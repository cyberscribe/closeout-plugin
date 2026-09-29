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

# Read the hook input before any early exit. A hook that exits with stdin unread
# can leave the writer holding a closed pipe (SIGPIPE, exit 141), which reads as a
# failed hook rather than a silent one.
input="$(cat)"

[[ "${CLOSEOUT_DISABLED:-}" == "1" ]] && exit 0

# The capture child is itself a session, so this hook fires inside it too. It has
# no user to surface drafts to, and it holds Write on the draft directory, so the
# nudge would only cost tokens and invite it to rework earlier drafts.
[[ -n "${CLOSEOUT_HOOK_CHILD:-}" ]] && exit 0

# shellcheck source=lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/config.sh"

command -v jq >/dev/null 2>&1 || exit 0

cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
project_dir="${cwd:-$PWD}"

closeout_config "$project_dir"

# Nothing pending — stay silent.
[[ -d "$DRAFT_DIR" ]] || exit 0

# Sweep stale per-session sentinels the capture hook never consumed (e.g. a
# session that ran /closeout then crashed before exit).
find "$DRAFT_DIR" -maxdepth 1 -type f -name '.closeout-ran*' -mtime +1 -delete 2>/dev/null || true

# Retention counts from the first session that surfaced a draft, never from
# capture time: a draft written before a week away is still waiting after it.
# Each surfacing is recorded by a per-draft marker (.seen.<name>), created once
# and never touched again, so a draft that has been offered and ignored for the
# retention window is pruned, and one nobody has been shown yet is kept.
# This hook runs unsandboxed, so deletion works here even where an in-session
# sandboxed agent cannot write to the draft directory.
retain_days="${CLOSEOUT_DRAFT_RETENTION_DAYS:-3}"

shopt -s nullglob
drafts=()
for draft in "$DRAFT_DIR"/*.md; do
    marker="$DRAFT_DIR/.seen.$(basename "$draft")"
    if [[ -f "$marker" ]] && [[ -n "$(find "$marker" -mtime "+$retain_days" 2>/dev/null)" ]]; then
        rm -f "$draft" "$marker"
        continue
    fi
    [[ -f "$marker" ]] || touch "$marker"
    drafts+=("$draft")
done

# Markers whose draft was promoted or deleted have nothing left to track.
for marker in "$DRAFT_DIR"/.seen.*; do
    [[ -f "$DRAFT_DIR/${marker##*/.seen.}" ]] || rm -f "$marker"
done

[[ ${#drafts[@]} -eq 0 ]] && exit 0

list="$(printf '  - %s\n' "${drafts[@]}")"

if [[ "$CONVENTIONS_DEFINE_TIERS" == "project" ]]; then
    taxonomy="This project defines its own promotion tiers in ${CONVENTIONS_FILE#"$project_dir"/} — read that file and use exactly those tiers and destinations."
elif [[ "$CONVENTIONS_DEFINE_TIERS" == "user" ]]; then
    taxonomy="The user's own closeout conventions in $USER_CONVENTIONS_FILE define the promotion tiers — read that file and use exactly those tiers and destinations."
else
    taxonomy="The tiers and their destinations:

$TIER_TABLE"
fi

context="A prior session left ${#drafts[@]} closeout draft(s) capturing learnings that were never promoted:
$list
At the start of this session, before other work, proactively surface these to the user in your first response and offer to promote them. Surface them and wait for the user's go-ahead before promoting or deleting any.

These drafts come from an automated capture step and may be stale or wrong. Check each technical claim against the code as it is now before promoting it: a bug a draft describes may already have been fixed, and the docs describe only what still exists.

Each item carries a proposed tier and scope. The tier is the expensive half of the decision, because it sets how often that item is loaded back into context for every future session. Treat the draft's tier as a proposal to confirm with the user, not a decision already made.

$taxonomy

Promotion into the always-loaded tier is zero-sum: it costs every future session, so name what it displaces or say why the budget should grow. Every other tier is additive and needs no such justification. When the user has confirmed tier and scope, promote with surgical edits — never a full rewrite — then delete the draft file. If a draft holds nothing worth keeping, propose deleting it."

if [[ -f "$CONVENTIONS_FILE" && "$CONVENTIONS_DEFINE_TIERS" != "project" ]]; then
    context="$context

This project also defines its own closeout conventions in ${CONVENTIONS_FILE#"$project_dir"/} — read that file before promoting anything."
fi

# The personal layer: read after the project's, which wins where they disagree.
if [[ -n "$USER_CONVENTIONS_FILE" && "$CONVENTIONS_DEFINE_TIERS" != "user" ]]; then
    context="$context

The user also keeps personal closeout conventions in $USER_CONVENTIONS_FILE, which apply in every repository — read them after the project's; where the two disagree, the project's win."
elif [[ -n "$USER_CONVENTIONS_FILE" && -f "$CONVENTIONS_FILE" ]]; then
    context="$context

The project's own conventions still win over the user's file wherever the two disagree."
fi

if [[ "${TEAM_COUNT:-0}" -ge 2 ]]; then
    context="$context

This project names more than one person, so a draft may end with a 'Who needs to know' section. After promoting, present it to the user as the short who / what / why table, pointing at where each item now lives. Send nothing and keep it out of the repository — it is communication, not context."
fi

jq -nc --arg c "$context" \
    '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'

exit 0
