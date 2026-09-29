#!/usr/bin/env bash
# The variables set here are read by the hooks that source this file.
# shellcheck disable=SC2034
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
#
# Conventions come in two layers, read in this order: the project's
# .claude/closeout.md, then the person's own ~/.claude/closeout.md. The project's
# wins wherever the two disagree; the personal file fills in where the project is
# silent, and both override the plugin's defaults.

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
#       USER_CONVENTIONS_FILE, CONVENTIONS_DEFINE_TIERS, TIERS_FILE,
#       TEAM_MEMBERS, TEAM_COUNT, WHO_NEEDS_TO_KNOW, ROSTER_FILE, ROSTER_ROWS,
#       ROSTER_REJECTED
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

    # The person's own conventions, above every repository they work in: an extra
    # destination or house rule of theirs. Empty when there is no such file.
    # CLOSEOUT_USER_CONVENTIONS names another path; set to an empty value, it
    # leaves the personal layer out (tests use that to stay independent of the
    # machine they run on).
    USER_CONVENTIONS_FILE="${CLOSEOUT_USER_CONVENTIONS-$HOME/.claude/closeout.md}"
    [[ -n "$USER_CONVENTIONS_FILE" && -f "$USER_CONVENTIONS_FILE" ]] || USER_CONVENTIONS_FILE=""

    # A conventions file may replace the whole taxonomy rather than just move
    # destinations, by carrying a "## Promotion tiers" section. When one does, the
    # plugin's default table is suppressed so the prompts never carry two competing
    # tier lists. The project's section wins; a personal one applies only where the
    # project defines none. CONVENTIONS_DEFINE_TIERS says whose ("project" or
    # "user"), TIERS_FILE which file holds them.
    CONVENTIONS_DEFINE_TIERS=""
    TIERS_FILE=""

    # The people this project names, for the optional "who needs to know" step,
    # which only applies when there are two or more. An explicit CLOSEOUT_TEAM list
    # wins. Otherwise: one entry per profile in the people directory (named by file,
    # README excluded), any bullet under a "## Team" heading in the conventions
    # file, and everyone on the team roster. Computed here rather than by the capture child, because the child is
    # deliberately unable to read the repository.
    #
    # The "Who needs to know: auto | ask | off" line sets the step: the project's
    # conventions first, then the person's own, else auto. A project README can
    # override it in its People section; the hooks cannot tell which project a
    # session worked in, so that override is the /closeout command's to apply.
    WHO_NEEDS_TO_KNOW=""
    local f
    for f in "$CONVENTIONS_FILE" "$USER_CONVENTIONS_FILE"; do
        [[ -n "$f" && -f "$f" ]] || continue
        # shellcheck disable=SC2016 # the backquotes are literal: a value may be written as `ask`
        WHO_NEEDS_TO_KNOW="$(sed -nE 's/^[[:space:]]*([-*][[:space:]]+)?(\*\*)?[Ww]ho needs to know:(\*\*)?[[:space:]]*`?(auto|ask|off)`?([^[:alnum:]].*)?$/\4/p' "$f" | head -n 1)"
        [[ -n "$WHO_NEEDS_TO_KNOW" ]] && break
    done
    WHO_NEEDS_TO_KNOW="${WHO_NEEDS_TO_KNOW:-auto}"

    # The team roster (templates/team-roster.md): one table row per person, with
    # a default relationship, a channel and a handle. Names are folded to the
    # people directory's file naming (lowercase, hyphens) so one person counted
    # from both is counted once. A cell carrying an email address or a phone
    # number is kept out of every prompt, and its person named in ROSTER_REJECTED:
    # contact details belong in a profile or an address book, not the repository.
    ROSTER_FILE="${CLOSEOUT_ROSTER-team/people.md}"
    [[ -n "$ROSTER_FILE" && "$ROSTER_FILE" != /* ]] && ROSTER_FILE="$project_dir/$ROSTER_FILE"
    # An explicit CLOSEOUT_TEAM wins outright, so the roster is then left unread.
    [[ -n "$ROSTER_FILE" && -f "$ROSTER_FILE" && -z "${CLOSEOUT_TEAM:-}" ]] || ROSTER_FILE=""
    ROSTER_ROWS="" ROSTER_REJECTED=""
    if [[ -n "$ROSTER_FILE" ]]; then
        # Output per row: slug|default relationship|channel|handle|flag (flag 1 when
        # a contact detail was removed from the row). A row whose Name cell holds a
        # contact detail is left out and named by its line number ("line N").
        local parsed
        parsed="$(awk -F'|' '
            function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
            # An email address in any cell; seven or more digits in one run of phone
            # characters only in the Channel and Handle cells, where a number would be
            # a contact (a figure in Role or Default relationship is not one). A date
            # written YYYY-MM-DD is taken out first, so it never reads as a number.
            function email(s) { return s ~ /[[:alnum:]._%+-]+@[[:alnum:]-]+(\.[[:alnum:]-]+)*\.[[:alpha:]][[:alpha:]]+/ }
            function phone(s,   t, d, n, part, i) {
                t = s; gsub(/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/, "|", t)
                gsub(/[^0-9+(). -]/, "|", t); n = split(t, part, "|")
                for (i = 1; i <= n; i++) { d = part[i]; gsub(/[^0-9]/, "", d); if (length(d) >= 7) return 1 }
                return 0
            }
            /^[[:space:]]*\|/ {
                name = trim($2)
                if (name == "" || tolower(name) == "name" || name ~ /^:?-+:?$/ || name ~ /^</) next
                if (email(name) || phone(name)) { print "line " NR "||||1"; next }
                flag = 0
                for (c = 3; c <= 6; c++) {
                    v[c] = trim($c)
                    if (email(v[c]) || (c >= 5 && phone(v[c]))) { v[c] = ""; flag = 1 }
                }
                slug = tolower(name); gsub(/[^[:alnum:]]+/, "-", slug); gsub(/^-+|-+$/, "", slug)
                print slug "|" v[4] "|" v[5] "|" v[6] "|" flag
            }' "$ROSTER_FILE")"
        ROSTER_ROWS="$(printf '%s\n' "$parsed" | grep -v '^$' | grep -v '^line [0-9]' | cut -d'|' -f1-4 || true)"
        ROSTER_REJECTED="$(printf '%s\n' "$parsed" | awk -F'|' '$5 == 1 { print $1 }' | paste -sd, - || true)"
    fi

    TEAM_MEMBERS=""
    if [[ -n "${CLOSEOUT_TEAM:-}" ]]; then
        TEAM_MEMBERS="$(printf '%s' "$CLOSEOUT_TEAM" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' || true)"
    else
        local people_dir="${CLOSEOUT_PEOPLE_DIR:-}" d
        if [[ -z "$people_dir" ]]; then
            for d in memory/people docs/people people; do
                [[ -d "$project_dir/$d" ]] && { people_dir="$d"; break; }
            done
        fi
        if [[ -n "$people_dir" && -d "$project_dir/$people_dir" ]]; then
            TEAM_MEMBERS="$(find "$project_dir/$people_dir" -maxdepth 1 -type f -name '*.md' ! -iname 'README.md' \
                -exec basename {} .md \; 2>/dev/null | sort)"
        fi
        if [[ -f "$CONVENTIONS_FILE" ]]; then
            local listed
            listed="$(awk 'tolower($0) ~ /^#+[[:space:]]*team[[:space:]]*$/ { f = 1; next }
                           /^#/ { f = 0 }
                           f && /^[[:space:]]*[-*][[:space:]]+/ { sub(/^[[:space:]]*[-*][[:space:]]+/, ""); print }' \
                "$CONVENTIONS_FILE")"
            TEAM_MEMBERS="$(printf '%s\n%s\n' "$TEAM_MEMBERS" "$listed" | grep -v '^$' | sort -u || true)"
        fi
        if [[ -n "$ROSTER_ROWS" ]]; then
            TEAM_MEMBERS="$(printf '%s\n%s\n' "$TEAM_MEMBERS" "$(printf '%s\n' "$ROSTER_ROWS" | cut -d'|' -f1)" | grep -v '^$' | sort -u || true)"
        fi
    fi
    TEAM_COUNT="$(printf '%s' "$TEAM_MEMBERS" | grep -c . || true)"
    if [[ -f "$CONVENTIONS_FILE" ]] &&
       grep -qiE '^#{1,6}[[:space:]]*promotion tiers' "$CONVENTIONS_FILE" 2>/dev/null; then
        CONVENTIONS_DEFINE_TIERS="project"
        TIERS_FILE="$CONVENTIONS_FILE"
    elif [[ -n "$USER_CONVENTIONS_FILE" ]] &&
       grep -qiE '^#{1,6}[[:space:]]*promotion tiers' "$USER_CONVENTIONS_FILE" 2>/dev/null; then
        CONVENTIONS_DEFINE_TIERS="user"
        TIERS_FILE="$USER_CONVENTIONS_FILE"
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
