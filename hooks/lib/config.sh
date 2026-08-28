#!/usr/bin/env bash
# Shared configuration resolution for the closeout hooks.
#
# Sourced by closeout-capture.sh and closeout-review.sh. Both hooks must agree on
# the draft location and on the promotion taxonomy, so that logic lives here once.
#
# Everything is overridable. Destinations move by environment variable (set them
# under "env" in the consuming project's .claude/settings.json, the only place a
# plugin user can inject configuration a hook will see). The taxonomy itself — the
# tier names, how many there are, what each one means — is replaced wholesale by a
# "## Promotion tiers" section in the project's .claude/closeout.md.

# closeout_first_existing <project_dir> <candidate>...
# Echoes the first candidate that exists, or the first candidate if none do, so a
# destination is always named even in a repo that has not created it yet.
closeout_first_existing() {
    local project_dir="$1"; shift
    local c
    for c in "$@"; do
        [[ -e "$project_dir/$c" ]] && { printf '%s' "$c"; return; }
    done
    printf '%s' "$1"
}

# closeout_config <project_dir>
#
# Sets: DRAFT_DIR, DOC_DIR, DECISIONS_FILE, TIER_TABLE, CONVENTIONS_FILE,
#       CONVENTIONS_DEFINE_TIERS
closeout_config() {
    local project_dir="${1:-$PWD}"

    # Drafts live outside any repo: never committed by accident, per-user, and
    # persistent across reboots. Keyed by project so review stays scoped.
    local draft_root="${CLOSEOUT_DRAFT_ROOT:-$HOME/.claude/closeout-drafts}"
    DRAFT_DIR="$draft_root/$(basename "$project_dir")"

    # Optional per-project conventions. A team's own closeout rules go here and
    # both the command and the capture prompt follow them. This is the single
    # extension point — no config schema to learn.
    CONVENTIONS_FILE="$project_dir/.claude/closeout.md"

    # A project may replace the whole taxonomy rather than just move destinations,
    # by giving its conventions file a "## Promotion tiers" section. When it does,
    # the plugin's default table is suppressed so the prompts never carry two
    # competing tier lists.
    CONVENTIONS_DEFINE_TIERS=""
    if [[ -f "$CONVENTIONS_FILE" ]] &&
       grep -qiE '^#{1,6}[[:space:]]*promotion tiers' "$CONVENTIONS_FILE" 2>/dev/null; then
        CONVENTIONS_DEFINE_TIERS="1"
    fi

    # Where per-project reference lives. Explicit override wins; otherwise pick the
    # first conventional docs directory that exists, and fall back to the repo root
    # for projects that keep documentation beside the code.
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

    TIER_TABLE=""
    [[ -n "$CONVENTIONS_DEFINE_TIERS" ]] && return

    # Shared destination per tier. Each is an env override, else the first
    # conventional location that exists in this repo.
    local t_always t_general t_project t_templates
    t_always="${CLOSEOUT_TIER_ALWAYS:-$(closeout_first_existing "$project_dir" CLAUDE.md AGENTS.md)}"
    t_general="${CLOSEOUT_TIER_GENERAL:-$(closeout_first_existing "$project_dir" .claude/skills/ .claude/plugins/)}"
    if [[ "$DOC_DIR" == "." ]]; then
        t_project="${CLOSEOUT_TIER_PROJECT:-README.md, $DECISIONS_FILE}"
    else
        t_project="${CLOSEOUT_TIER_PROJECT:-$DOC_DIR/, $DECISIONS_FILE}"
    fi
    t_templates="${CLOSEOUT_TIER_TEMPLATES:-$(closeout_first_existing "$project_dir" .claude/agents/ .claude/commands/)}"

    # Individual scope is a Claude Code convention rather than a repo layout, so it
    # is derived, not detected. The per-project memory directory is keyed by the
    # absolute path with separators and word characters folded to dashes.
    local mem_slug="${project_dir//\//-}"
    mem_slug="${mem_slug//_/-}"
    mem_slug="${mem_slug//./-}"

    TIER_TABLE="$(cat <<EOF
| Tier | Loaded back | Shared destination (committed) | Individual destination (this machine only) |
|---|---|---|---|
| Working standards | ALWAYS — every session, every turn | $t_always | ~/.claude/CLAUDE.md |
| General reference | as needed, in ANY project | $t_general | ~/.claude/skills/ |
| Project reference | as needed, only in THIS project | $t_project | ~/.claude/projects/$mem_slug/memory/ |
| Templates & agent roles | as needed, when that role or scaffold is invoked | $t_templates | ~/.claude/agents/ |
EOF
)"
}
