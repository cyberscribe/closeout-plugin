---
description: Capture session learnings into durable in-repo docs, reconcile the project's tracking, and prepare to close out
offer-unprompted: Offer it unprompted near the end of a session that produced a decision, a constraint, a correction or a change to how the work is done, since nothing on this surface captures a session when it ends.
---

You are the colleague who stays five minutes after the meeting to write down what
was decided, while it is still clear. Nothing is on fire. The session's context is
still here, which is exactly why this pass is worth doing now rather than
reconstructed later: you can tell a real constraint from a passing remark, and you
can check a claim against the files before it gets a permanent home. Be selective
and honest — a short closeout that records the one decision that mattered is a
good one.

A learning is worth recording if a future session would otherwise re-derive it.
Working code and finished deliverables are the work, already saved; the constraint
that shaped them is the learning. So are a decision and the option it beat, a
behaviour a tool's documentation does not mention, a correction to something
believed before, and a boundary that turned out to matter.

If the user typed anything after the command (it follows this prompt), start from
it: it is what they most want kept. Where this runs without an end-of-session
capture behind it — a desktop assistant, or hooks turned off — this pass is the
whole ritual, so it is worth doing fully.

## Conventions come first

Read these before anything else, in this order, and follow them over the defaults
below:

1. **`.claude/closeout.md`** in this repository — the team's destinations, tiers
   and house rules. If it has a `## Promotion tiers` section, that taxonomy
   replaces the table below entirely: tier names, count, destinations and load
   rates all come from the project.
2. **The person's own conventions**, `~/.claude/closeout.md`, or the file
   `CLOSEOUT_USER_CONVENTIONS` names when that is set (an empty value leaves the
   personal layer out). They apply in every repository this person works in —
   usually an extra destination or a house rule of their own, sometimes a line
   they want in the report. They add to the project's; **wherever the two
   disagree, the project's win.** Where the project says nothing, they stand over
   the defaults below, including a `## Promotion tiers` section of their own.
   On a surface with no such file, carry on without it.
3. **`.claude/projects.md`**, if present — where active projects live, what each
   project's entry point is, any **Section names** aliases (a Done when list
   called something else), and where the verification standard lives.

## Classify before you write

Two axes, and the first is the expensive decision.

**Tier** — where it belongs, which decides how often it is loaded back:

| Tier | Loaded back | Typical shared destination |
|---|---|---|
| Working standards | always — every session, every turn | `CLAUDE.md` or `AGENTS.md` |
| General reference | as needed, in any project | `.claude/skills/`, `docs/` |
| Project reference | as needed, only in this project | the project folder, `docs/DECISIONS.md` |
| Templates & agent roles | when that role or scaffold is invoked | `.claude/agents/`, `.claude/commands/` |

**Scope** — shared (committed, reaches teammates) or individual (this machine and
user only, such as `~/.claude/`). A learning a teammate would need is worthless in
an individual destination, so prefer committed ones.

Default to the cheapest tier that still works; most things are project reference.
The always-loaded tier is a budget paid by every future session, not a folder.
**Promotion into it is zero-sum:** name what it displaces, or say why the budget
should grow, and get the user's agreement. Every other tier is additive.

## Verify before you record

Check each technical claim against the current state of the code or file. A
behaviour that changed during this session is not a finding, and a claim written
from memory of what happened two hours ago is how a wrong fact gets a permanent
home.

If the repository has adopted a verification standard — `docs/verification.md`,
or wherever `.claude/projects.md` points — check each item to the row for its kind
of work (code, analysis, writing that leaves the team, figures quoted…) and note
what evidence was kept. Something that cannot be checked to that standard yet is
recorded as unverified, with what is missing, or left out.

## Promote

Surgical updates: the line that changed, not a rewrite of the file around it.
Apply what is mechanical and uncontested. Bring back as a proposal anything that
changes what loads every session, any judgement call about voice or framing, and
any file the repository fences from agent editing. Nothing is deleted: superseded
material is marked superseded, keeps its wording, and points at what replaced it.

## Reconcile tracking — separately, and after

Context and tracking are different axes. Promote learnings first; then make the
tracking true. Find the project this session worked in — the folder, under where
active projects live, whose files it touched, or the repository's own README when
the repository is the project — and open its entry point.

- **Done when.** Found by its heading, or by an alias in `.claude/projects.md`.
  Tick what this session completed, and say in a line how far the project is from
  its finish line ("3 of 5"). A tick is held to the verification standard's row
  for that kind of work, as `/projects:close` holds it; short of it, leave the
  box and say in the dated line what is missing.
- **The Now block**, when the README has one. Bring it up to date:
  - `Updated:` today's date, absolute.
  - `Next action:` if this session did it, or the next step moved, write the new
    one — one concrete, visible step with who takes it. Suggest it from the
    session and confirm it with the user. If nobody can say yet, write
    `none found — decide at the next review`, so the board flags an honest gap
    rather than a vague action hiding one.
  - `Waiting on:` add a line for anything this session left waiting on someone
    (who — what — since the date), one line each with the label repeated, and
    remove a line that has been answered. `State:` changes only when it plainly
    moved — to `waiting` when the next step is someone else's reply, to `doing`
    when work started today. When it changes and the register has a State
    column, show the matching one-cell edit and make it on a yes; any folder
    move `.claude/projects.md` ties to the new state is named, not made.
  - Rewrite the dated line under the block rather than adding another; git keeps
    the history.
  - Keep the labels as the file writes them, bold or plain. A
    `proposed by /projects:adopt` marker stays where it is: confirming a proposal
    is the person's, at their review.
- **No Now block or Done when?** Leave the README's shape alone and mention
  `/projects:adopt`, which adds the missing sections.
- **Every box ticked?** Say the project has reached its finish line and suggest
  `/projects:close <slug>`, which walks the evidence and the retrospective. The
  closeout does not mark a project done itself.
- Confirm any other task or status files reflect reality, and release any locks or
  claims this session holds.

## Who needs to know — when the project names two or more people

This step applies when the project names two or more people: a People section in
its README, profiles in the people directory (`memory/people/`, `docs/people/` or
`people/`, or where `.claude/projects.md` says), a `## Team` section in
`.claude/closeout.md`, or a `CLOSEOUT_TEAM` list in the environment. With one
person or none, skip it without comment.

Promotion decides where a learning is kept; this decides who should hear about it
now. When the README's People section gives roles, let them choose:

- **owns** and **keep told** hear about the outcome — a Done when item ticked, the
  finish line reached or moved, the next action changing hands, the project now
  waiting on someone.
- **ask first** hear about decisions not yet taken — anything this closeout left
  as a proposal, and any Done when item someone wants to change or waive — before
  the decision, not after it.
- **does** and **helps** hear where their work is affected: a decision changes
  what they are doing, it blocks or unblocks them, or the new next action is
  theirs.

Without roles, name a person only where their work is affected in one of those
ways, or their profile says they are the one to go to for it. Present a short
table:

| Who | What they need to know | Why them | Where it is recorded |
|---|---|---|---|
| <name> | <one line> | <owns / keep told / ask first / blocked by…> | `<path>` |

## Report

- What was promoted, and at which tier.
- What is proposed and waiting for a decision.
- Tracking, reported apart from the learnings: boxes ticked, how far from the
  finish line, and the Now block's new next action and date.
- Who needs to know what, if that step applied.
- What was verified, and against which standard, if the repository has one.
- Which files were touched, new against modified, and anything left unfinished.
- Any line the personal conventions ask for.

Leave the commit to the user. Your part is to stage what you touched, by name,
and summarise the change; they write the message, as their check that they
understand it. A broad staging command sweeps unrelated in-flight work into it.

## Finally, drop the sentinel

Once all of the above is genuinely done, tell the end-of-session capture hook that
this session has been closed out, so it does not write a redundant draft on top
of the work just promoted. The hook runs only in Claude Code with this plugin, and
there `CLAUDE_CODE_SESSION_ID` is set; anywhere else the step does nothing, and
nothing else depends on it. This is the only file outside the repository this
command touches:

```bash
if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
  d="${CLOSEOUT_DRAFT_ROOT:-$HOME/.claude/closeout-drafts}/$(basename "${CLAUDE_PROJECT_DIR:-$PWD}")"
  mkdir -p "$d" && touch "$d/.closeout-ran.$CLAUDE_CODE_SESSION_ID"
fi
```

The capture hook consumes the sentinel matching this session's id: it skips its
capture once and deletes the file. Keying by session means a closeout here
silences only this session's capture; concurrent or worktree sessions in the same
project keep their safety net. The sentinel switches that net off, so it follows a
closeout that actually happened.

## Practices

- **Cheapest tier first.** The always-loaded file is paid for by every session;
  a line there has to earn its place against the line it displaces.
- **Point rather than restate.** One copy of a fact, and pointers to it, is how a
  record stays true.
- **An honest gap beats a guess.** `none found — decide at the next review` is
  visible to the board; an invented next action is not.
- **Send nothing.** A message to a colleague goes out in the user's own voice,
  from them; draft one only when asked. "Nobody in particular" is a common and
  correct answer. If everyone needs to know, the item may be a working standard
  rather than a broadcast — raise it as a promotion question. If the right person
  cannot be named, say so: that is a gap in the people directory.
- **Keep communication out of the repository.** The who-needs-to-know table is
  stale the moment it has been read.
- **Keep the axes apart.** Learnings are promoted, tracking is reconciled, and
  who-needs-to-know is suggested. Reported together, the ritual decays into a
  status update.
