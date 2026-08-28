#!/usr/bin/env bash
# Shared configuration resolution for the closeout hooks.
#
# Sourced by closeout-capture.sh and closeout-review.sh. Both hooks must agree
# on the draft location and the doc targets, so that logic lives here once.
#
# Everything is overridable by environment variable — set them in the consuming
# project's .claude/settings.json under "env", which is the only place a plugin
# user can inject configuration a hook will see.

# closeout_config <project_dir>
#
# Sets: DRAFT_DIR, DOC_DIR, DECISIONS_FILE, DOC_TARGETS, CONVENTIONS_FILE
closeout_config() {
    local project_dir="${1:-$PWD}"

    # Drafts live outside any repo: never committed by accident, per-user, and
    # persistent across reboots. Keyed by project so review stays scoped.
    local draft_root="${CLOSEOUT_DRAFT_ROOT:-$HOME/.claude/closeout-drafts}"
    DRAFT_DIR="$draft_root/$(basename "$project_dir")"

    # Where durable learnings belong. Explicit override wins; otherwise pick the
    # first conventional docs directory that exists, and fall back to the repo
    # root for projects that keep documentation beside the code.
    if [[ -n "${CLOSEOUT_DOC_DIR:-}" ]]; then
        DOC_DIR="$CLOSEOUT_DOC_DIR"
    elif [[ -d "$project_dir/docs" ]]; then
        DOC_DIR="docs"
    elif [[ -d "$project_dir/doc" ]]; then
        DOC_DIR="doc"
    elif [[ -d "$project_dir/documentation" ]]; then
        DOC_DIR="documentation"
    else
        DOC_DIR="."
    fi

    if [[ -n "${CLOSEOUT_DECISIONS_FILE:-}" ]]; then
        DECISIONS_FILE="$CLOSEOUT_DECISIONS_FILE"
    elif [[ "$DOC_DIR" == "." ]]; then
        DECISIONS_FILE="DECISIONS.md"
    else
        DECISIONS_FILE="$DOC_DIR/DECISIONS.md"
    fi

    # Human-readable target list used in both the capture prompt and the review
    # nudge, so the agent names real destinations rather than guessing.
    if [[ "$DOC_DIR" == "." ]]; then
        DOC_TARGETS="README.md or $DECISIONS_FILE at the repo root"
    else
        DOC_TARGETS="$DOC_DIR/ and $DECISIONS_FILE"
    fi
    [[ -n "${CLOSEOUT_DOC_TARGETS:-}" ]] && DOC_TARGETS="$CLOSEOUT_DOC_TARGETS"

    # Optional per-project addendum. If a team has its own closeout conventions
    # (extra tracking files, a role-scoped queue, a house style for doc edits),
    # they write them here and both the hook and /closeout honour them. This is
    # the single extension point — no config schema to learn.
    CONVENTIONS_FILE="$project_dir/.claude/closeout.md"
}
