#!/usr/bin/env bash
# SessionEnd auto-capture for the closeout ritual.
#
# A good habit is to end a session by asking the agent to record what it learned
# and update the durable in-repo docs. Anyone who forgets that step loses those
# learnings. This hook is the safety net: on session end it spawns a SEPARATE,
# detached headless `claude -p` that reads the just-ended transcript and writes
# candidate doc-notes to a scratch file OUTSIDE the repo. The next session in
# this project is pointed at that file by closeout-review.sh, to review and
# promote anything durable.
#
# It cannot make the *current* agent do the work: SessionEnd fires after the
# agent loop is over and its stdout is not injected into context. Hence the
# detached child, which is fully detached so the human's exit is never delayed.
#
# Wired from hooks/hooks.json -> hooks.SessionEnd. Receives the SessionEnd JSON
# on stdin.

set -euo pipefail

# (1) Recursion guard — CRITICAL. The headless child below ALSO triggers a
# SessionEnd when it finishes; without this it would spawn children forever.
if [[ -n "${CLOSEOUT_HOOK_CHILD:-}" ]]; then
    exit 0
fi

# (2) Global off switch, for projects that want /closeout without the backstop.
[[ "${CLOSEOUT_DISABLED:-}" == "1" ]] && exit 0

# shellcheck source=lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/config.sh"

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"

reason="$(printf '%s' "$input" | jq -r '.reason // empty')"
transcript_path="$(printf '%s' "$input" | jq -r '.transcript_path // empty')"
session_id="$(printf '%s' "$input" | jq -r '.session_id // empty')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"

# (3) Skip noise: /clear is not a real closeout, and a missing or unreadable
# transcript means there is nothing to capture.
[[ "$reason" == "clear" ]] && exit 0
[[ -z "$transcript_path" || ! -f "$transcript_path" ]] && exit 0

# (4) Skip trivial sessions — a handful of transcript lines is not worth a run.
min_lines="${CLOSEOUT_MIN_LINES:-6}"
lines="$(wc -l < "$transcript_path" 2>/dev/null || echo 0)"
[[ "$lines" -lt "$min_lines" ]] && exit 0

# (5) Resolve the claude binary in a PATH-independent way — hooks run with a
# minimal environment that often misses a user's shell PATH additions.
CLAUDE_BIN="${CLOSEOUT_CLAUDE_BIN:-$(command -v claude || true)}"
[[ -z "$CLAUDE_BIN" && -x "$HOME/.local/bin/claude" ]] && CLAUDE_BIN="$HOME/.local/bin/claude"
[[ -z "$CLAUDE_BIN" && -x "/usr/local/bin/claude" ]] && CLAUDE_BIN="/usr/local/bin/claude"
[[ -z "$CLAUDE_BIN" ]] && exit 0

project_dir="${cwd:-$PWD}"
closeout_config "$project_dir"
mkdir -p "$DRAFT_DIR"

# (6) Suppression handshake with the /closeout command. When someone runs
# /closeout in-session, it already promotes durable learnings into the in-repo
# docs and drops a PER-SESSION sentinel here (.closeout-ran.<session_id>). Honor
# only the sentinel matching THIS ending session: skip the redundant auto-capture
# and remove it. A stale sentinel (older than 6h) is cleared but NOT honored, so
# an old closeout can never silence captures indefinitely.
#
# Keying by session id (not just project) means a /closeout in one session
# suppresses only that session's capture — concurrent or worktree sessions in the
# same project keep their own safety net, instead of the first session to end
# consuming a single shared sentinel and the rest writing spurious drafts.
if [[ -n "$session_id" ]]; then
    sentinel="$DRAFT_DIR/.closeout-ran.$session_id"
    if [[ -f "$sentinel" ]]; then
        fresh="$(find "$sentinel" -mmin -360 2>/dev/null)"
        rm -f "$sentinel"
        [[ -n "$fresh" ]] && exit 0
    fi
fi

# Sweep stale sentinels so they never accumulate.
find "$DRAFT_DIR" -maxdepth 1 -type f -name '.closeout-ran.*' -mmin +360 -delete 2>/dev/null || true

draft_file="$DRAFT_DIR/${session_id:-$(date +%s)}.md"

# (7) The promotion taxonomy. A project that defines its own tiers owns the
# section outright; otherwise the plugin's default table is supplied.
if [[ -n "$CONVENTIONS_DEFINE_TIERS" ]]; then
    taxonomy="This project defines its own promotion tiers. Use exactly those — the
tier names, destinations and load rates below come from the project, and no other
taxonomy applies."
else
    taxonomy="TIER — where it belongs, which decides how often it is loaded back:

$TIER_TABLE

SCOPE — shared (committed, reaches teammates) or individual (this machine and
user only). A learning a teammate would need is worthless in an individual
destination."
fi

# Per-project conventions, if the team wrote any, appended verbatim.
conventions=""
if [[ -f "$CONVENTIONS_FILE" ]]; then
    conventions="

This project's own closeout conventions follow. They override everything above —
tier names, destinations, load rates, and any house rules:

$(cat "$CONVENTIONS_FILE")"
fi

read -r -d '' PROMPT <<EOF || true
You are reviewing a just-ended Claude Code session for this project to capture
durable learnings before they are lost. Read the session transcript (JSONL) at:
  $transcript_path

Identify only DURABLE facts a future agent would otherwise have to re-derive:
architectural/structural decisions made, non-obvious constraints discovered,
state of in-progress work, and gotchas. Ignore routine edits and chit-chat.

Classify every item you keep on two axes before writing it down.

$taxonomy

Default to the CHEAPEST tier that still works, and prefer a narrower scope when
in doubt. The always-loaded tier is a budget paid by every future session, not a
folder: put something there only if a session that never thought to ask for it
would still go wrong without it. Everything else is cheaper as reference that
loads on demand.

Write a concise markdown summary of candidate documentation updates to:
  $draft_file

One section per item, in this shape:

  ### <one-line claim>
  - tier: <tier name>
  - scope: shared | individual
  - destination: <the specific file or directory>
  - why this tier: <one sentence; say what would go wrong at a cheaper tier>

  <the note itself, one to three sentences>

Do NOT edit any in-repo documentation yourself — only write the scratch summary
file. You are proposing; a human approves the tier before anything is promoted.

If nothing durable was learned, do not create the file at all.${conventions}
EOF

# (8) Spawn fully detached so the human's session exit is never blocked.
# Blast radius is bounded deliberately: Read/Write tools only, and --add-dir
# limited to exactly the transcript's directory (read) and the draft directory
# (write) — the child cannot touch the repo, settings, or other projects.
child_args=(
    "$CLAUDE_BIN" -p "$PROMPT"
    --model "${CLOSEOUT_MODEL:-sonnet}"
    --permission-mode acceptEdits
    --allowedTools "Read,Write"
    --add-dir "$DRAFT_DIR"
    --add-dir "$(dirname "$transcript_path")"
)

# Prefer setsid for a clean full detach, but it is not on stock macOS (only via
# MacPorts/Homebrew) and is absent on a stripped hook PATH. Fall back to
# nohup + disown, which survives the parent session exit on any POSIX shell.
if command -v setsid >/dev/null 2>&1; then
    CLOSEOUT_HOOK_CHILD=1 setsid nohup "${child_args[@]}" >/dev/null 2>&1 < /dev/null &
else
    CLOSEOUT_HOOK_CHILD=1 nohup "${child_args[@]}" >/dev/null 2>&1 < /dev/null &
    disown 2>/dev/null || true
fi

exit 0
