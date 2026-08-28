#!/usr/bin/env bash
# SessionStart review pointer for the closeout ritual.
#
# Companion to closeout-capture.sh. When a new session starts in this project,
# check for closeout drafts left by a prior session and, if any exist, inject a
# reminder (via additionalContext — the only injection SessionStart supports)
# telling the agent to review them and promote anything durable into the in-repo
# docs, then delete the draft. This is the step that makes a forgotten session's
# captured learnings actually reach the shared docs.
#
# Wired from hooks/hooks.json -> hooks.SessionStart (matcher startup|resume).

set -euo pipefail

[[ "${CLOSEOUT_DISABLED:-}" == "1" ]] && exit 0

# shellcheck source=lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/config.sh"

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"

closeout_config "${cwd:-$PWD}"

# Nothing pending — stay silent.
[[ -d "$DRAFT_DIR" ]] || exit 0

# Belt-and-braces cleanup: prune drafts older than the retention window so
# abandoned ones do not re-nudge for long. This hook runs unsandboxed, so
# deletion works here even where an in-session sandboxed agent cannot write to
# the draft directory. Also sweep stale per-session sentinels the capture hook
# never consumed (e.g. a session that ran /closeout then crashed before exit).
retain_days="${CLOSEOUT_DRAFT_RETENTION_DAYS:-3}"
find "$DRAFT_DIR" -maxdepth 1 -type f -name '*.md' -mtime "+$retain_days" -delete 2>/dev/null || true
find "$DRAFT_DIR" -maxdepth 1 -type f -name '.closeout-ran*' -mtime +1 -delete 2>/dev/null || true

shopt -s nullglob
drafts=("$DRAFT_DIR"/*.md)
[[ ${#drafts[@]} -eq 0 ]] && exit 0

list="$(printf '  - %s\n' "${drafts[@]}")"

context="A prior session left ${#drafts[@]} closeout draft(s) capturing learnings that were never promoted into the docs:
$list
At the start of this session, before other work, proactively surface these to the user in your first response and offer to promote them. Do NOT silently promote or delete — wait for the user's go-ahead. When promoting: these drafts are written by an automated capture step and CAN BE STALE OR WRONG, so before promoting any technical claim, verify it against the CURRENT code (a bug a draft describes may already have been fixed; do not document something that no longer exists). Promote only durable, verified items into the appropriate in-repo doc (${DOC_TARGETS}) as surgical edits, never a full rewrite, then delete the draft file. If a draft holds nothing worth keeping, propose deleting it."

if [[ -f "$CONVENTIONS_FILE" ]]; then
    context="$context

This project defines its own closeout conventions in ${CONVENTIONS_FILE#"${cwd:-$PWD}"/} — read that file before promoting anything."
fi

jq -nc --arg c "$context" \
    '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'

exit 0
