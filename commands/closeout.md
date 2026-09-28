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

## Who needs to know — only when the project has more than one person

This step is optional. It applies when the project names two or more people:
profiles in the people directory (`memory/people/`, `docs/people/` or `people/`),
a People or Team section in the project README or in `.claude/closeout.md`, or a
`CLOSEOUT_TEAM` list in the environment. With one person or none, skip it without
comment.

Promotion decides where a learning is kept; this decides who should hear about
it now. For each item promoted or proposed, name a person only where their work
is affected — they own the area it touches, a decision changes what they are
doing, it blocks or unblocks them, or their profile says they are the one to go
to for it. Present a short table:

| Who | What they need to know | Why them | Where it is recorded |
|---|---|---|---|

- "Nobody in particular" is a common and correct answer; say it in one line.
- If everyone needs to know, the item may be a working standard rather than a
  broadcast — raise it as a promotion question.
- Point at where the learning now lives rather than restating it.
- Send nothing. A message to a colleague goes out in the user's own voice, from
  them; draft one only when asked.
- If the right person cannot be named, say so — that is a gap in the people
  directory.
- Keep the table out of the repository. It is communication, not context.

## Then close out

Context and tracking are different things — promote learnings first, then
reconcile state separately:

- Confirm any task or tracking files this project keeps reflect reality.
- Release any locks or claims this session holds.
- Briefly summarise what was changed, at which tier, who needs to know (if that
  step applied), and flag any critical items remaining.

## Finally, drop the sentinel

Only after the above is genuinely done, signal that this session has been closed
out, so the automatic end-of-session capture hook does not write a redundant draft
on top of the work you just promoted. This is the only out-of-repo file this
command touches:

```bash
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" \
  && d="${CLOSEOUT_DRAFT_ROOT:-$HOME/.claude/closeout-drafts}/$(basename "$root")" \
  && mkdir -p "$d" \
  && touch "$d/.closeout-ran.${CLAUDE_CODE_SESSION_ID:-unknown}"
```

The `closeout-capture.sh` SessionEnd hook consumes the sentinel matching this
session's id: it skips the auto-capture exactly once and deletes it. Keying by
session id (not just project) means running `/closeout` in one session suppresses
only THAT session's capture — concurrent or worktree sessions in the same project
are unaffected. Do not create it unless you have actually completed the closeout
above — it suppresses the safety net.
