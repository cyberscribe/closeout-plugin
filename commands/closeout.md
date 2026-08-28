---
description: Capture session learnings into durable in-repo docs and prepare to close out
---

Review what was learned or decided this session, then promote anything durable
into the project's documentation. Make surgical updates only — never a full
rewrite of an existing doc.

A learning is worth recording if a future agent would otherwise re-derive it.

## Classify before you write

Two axes, and the first one is the expensive decision:

**Tier** — where it belongs, which decides how often it is loaded back into
context:

| Tier | Loaded back | Typical shared destination |
|---|---|---|
| Working standards | ALWAYS — every session, every turn | `CLAUDE.md` |
| General reference | as needed, in ANY project | `.claude/skills/` |
| Project reference | as needed, only in THIS project | `docs/`, `docs/DECISIONS.md` |
| Templates & agent roles | as needed, when that role or scaffold is invoked | `.claude/agents/`, `.claude/commands/` |

**Scope** — shared (committed, reaches teammates) or individual (this machine and
user only, e.g. `~/.claude/`). A learning a teammate would need is worthless in an
individual destination. Prefer committed destinations; a note in a gitignored
directory or a personal memory file reaches nobody else.

Default to the cheapest tier that still works. The always-loaded tier is a budget
paid by every future session, not a folder — put something there only if a session
that never thought to ask for it would still go wrong without it.

**Promotion into the always-loaded tier is zero-sum.** Name what it displaces, or
say why the budget should grow, and get the user to agree. Every other tier is
additive and needs no such justification.

## Project conventions override all of this

If `.claude/closeout.md` exists in this project, read it first. It names this
team's own destinations and house rules. If it contains a `## Promotion tiers`
section, that taxonomy replaces the table above entirely — tier names, count,
destinations and load rates all come from the project.

## Verify before you record

Check every technical claim against the current code. Do not document a bug or
behaviour that has since changed during this session.

## Then close out

Context and tracking are different things — promote learnings first, then
reconcile state separately:

- Confirm any task or tracking files this project keeps reflect reality.
- Release any locks or claims this session holds.
- Briefly summarise what was changed, at which tier, and flag any critical items
  remaining.

## Finally, drop the sentinel

Only after the above is genuinely done, signal that this session has been closed
out, so the automatic end-of-session capture hook does not write a redundant draft
on top of the work you just promoted. This is the only out-of-repo file this
command touches:

```bash
d="${CLOSEOUT_DRAFT_ROOT:-$HOME/.claude/closeout-drafts}/$(basename "$PWD")" \
  && mkdir -p "$d" \
  && touch "$d/.closeout-ran.${CLAUDE_CODE_SESSION_ID:-unknown}"
```

The `closeout-capture.sh` SessionEnd hook consumes the sentinel matching this
session's id: it skips the auto-capture exactly once and deletes it. Keying by
session id (not just project) means running `/closeout` in one session suppresses
only THAT session's capture — concurrent or worktree sessions in the same project
are unaffected. Do not create it unless you have actually completed the closeout
above — it suppresses the safety net.
