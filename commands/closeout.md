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
it: it is what they most want kept. With no end-of-session capture behind it — a
desktop assistant, or hooks turned off — this pass is the whole ritual.

## Conventions come first

Read these before anything else, in this order, and follow them over the defaults
below:

1. **`.claude/closeout.md`** in this repository — the team's destinations, tiers
   and house rules. If it has a `## Promotion tiers` section, that taxonomy
   replaces the table below entirely: tier names, count, destinations and load
   rates all come from the project.
2. **The person's own conventions**, `~/.claude/closeout.md` (or the file
   `CLOSEOUT_USER_CONVENTIONS` names; empty or missing means none). The project's
   win where the two disagree; elsewhere these stand over the defaults, tiers too.
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

In a workspace built on the kit, the always-loaded file is `CLAUDE.md`, and its
first line imports `kit/CLAUDE.kit.md`. That file, like everything under `kit/`,
is the kit's: its bytes count in the budget, but it changes by pull request to
the kit, not in a closeout. Promotions into working standards go below the
import line. A learning about the kit itself is drafted in the report, and an
edit inside `kit/` is made only with a person approving it. Where
`.claude/skills/.kit-generated` exists, `.claude/skills/` is the skills bridge's
generated copy, rewritten on its next run, so general reference goes to
`skills/` instead.

**Sensitive projects.** A project whose README reads `Sensitivity: sensitive` is
kept untracked or as its own private repository, and learnings from it land in its
own folder only. Nothing from it — a name, a figure, a finding, a quotation — is
promoted into a file the workspace tracks or shares: not `CLAUDE.md`, `docs/`,
`skills/`, the cross-project log, a people profile, nor a kit pull request. Where
a learning generalises, the report offers a stripped version and says it came from
a sensitive project; the person decides whether it travels.

**The cross-project filter.** Where the repository keeps a cross-project decisions
log (`logs/decisions.md`, or the one its conventions name), a decision goes there
only if it still means something with every reference to the project, technology,
file path and stakeholder stripped out; otherwise it stays in the project. When it
is unclear, it stays in the project — promotion is cheap, demotion is not. Use the
log's own entry format.

**Scope** — shared (committed, reaches teammates) or individual (this machine and
user only, such as `~/.claude/`). Prefer committed: a teammate cannot use the other.

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

When a line is promoted, or proposed for promotion, to one of the two tiers
loaded most often (by default working standards and general reference), offer an
ablation; it is an offer, and a no ends it. Ask what task would go worse without
the line. If there is one and the repository has `pilot/ablations/`, draft the
ablation file there — that task as the prompt, a Check, and the lines exactly as
they will read (format in `pilot/README.md`, or copy a file already in
`pilot/ablations/`) — listed in the commit plan with the promotion once it is agreed. If nobody can
name a task, say so plainly: that is evidence about the tier, and the cheaper
tier is usually the answer.

## Reconcile tracking — separately, and after

Context and tracking are different axes. Promote learnings first; then make the
tracking true. Find the project this session worked in — the folder under where
active projects live whose files it touched, or the repository's own README when
the repository is the project — and open its entry point.

- **Done when** (by its heading, or an alias in `.claude/projects.md`): tick what
  this session completed and say how far the project is from its finish line
  ("3 of 5"). A tick meets the verification standard's row for that kind of work,
  as `/projects:close` holds it; short of it, leave the box and say in the dated
  line what is missing.
- **Current state**, when the README has one, as the project template
  (`kit/templates/project-readme.md`, or the path `.claude/projects.md` names)
  defines it.
  Move `State:` only when the session plainly moved it — to `doing`, to `blocked`,
  or back once a blocker cleared; propose `paused`, which `/projects:hold` makes
  (the folder stays where it is), and leave `done` to `/projects:close`. Set or
  clear `Blocked by:` with the user, dated. Set
  `Updated:` to today and rewrite the dated line (add one if absent) to say where
  the work stands.
  The rest of the block — `Check-in:`, **Planned**, label style, a
  `proposed by /projects:adopt` marker — stays as it is. A state change shows the
  register's one-cell edit, made on a yes; a folder move tied to it is named, not
  made.
- **No Current state block or Done when, or an older Now block?** Leave the
  README's shape alone and mention `/projects:adopt`.
- **Every box ticked?** Say so and suggest `/projects:close <slug>`, which
  archives the folder to `projects/_done/<slug>/`, or wherever the conventions'
  `Done:` line says.
- Confirm other task or status files reflect reality, and release any locks or
  claims this session holds.

## Who needs to know — when two or more people are known

`Who needs to know:` in `.claude/closeout.md` is `auto` (the default), `ask` or
`off`; the same line in a project README's People section overrides it, and with
neither, the line in the person's own conventions applies. `off` skips this step;
`ask` offers it in one line and goes on only on a yes. The person's own conventions
set the step but add nobody to a project.

People are named in the README's People section, the team roster (`team/people.md`),
the people directory (`memory/people/`, `docs/people/`, `people/`, or where
`.claude/projects.md` says), a `## Team` section in `.claude/closeout.md`, or
`CLOSEOUT_TEAM`. A roster row with an email address, or a phone number outside its
channel and handle cells, is left out, and the report says whose: contact details
belong in a profile or an address book, not the repository.
The project's roles win over the roster's; the roster adds anyone
else whose default relationship, scoped or not, matches what changed. With one
person or none, skip this without comment. Where the People section gives roles:

- **owns**, **keep told**: the outcome — a box ticked, the finish line moved,
  ownership changed, a block.
- **ask first**: this closeout's proposals, a Done when change or waiver — before,
  not after.
- **does**, **helps**: work of theirs changed, blocked, unblocked or passed to them.

Without roles, name only those whose work is affected so, or whose profile makes
them the one to go to. Present a short table. **How** is their channel, from the
roster or the project; **Offer** is `draft` (a short message in the user's voice),
`note` (a line for the next team meeting or one-to-one) or `none`, picked per
row. Drafts are shown here; with a mail or chat tool connected, at most a draft
there, on an explicit yes.

| Who | What they need to know | Why them | How | Offer | Where it is recorded |
|---|---|---|---|---|---|
| <name> | <one line> | <owns / keep told / ask first / blocked by…> | <channel> | draft · note · none | `<path>` |

## Report

- What was promoted, and at which tier.
- What is proposed and still needs a decision.
- Any ablation offered: drafted, declined, or the tier reconsidered.
- Tracking, reported apart from the learnings: boxes ticked, how far from the
  finish line, and the Current state block's new state, blocker and date.
- Who needs to know what, if that step applied.
- What was verified, and against which standard, if the repository has one.
- Which files were touched, new against modified, and anything left unfinished.
- The commands that commit them, in the order below.
- Any line the personal conventions ask for.

Leave the commit to the person. List what you touched, by name (a broad staging
command sweeps in unrelated work), and give the commands for them to run, with
each message editable. Where a file you touched sits inside a submodule — for
example the kit at `kit/`, or a project that is its own repository — the
commands come in this order: inside the submodule, add, commit and push; then,
in the workspace, add the submodule's path (`git add kit`) with the other files,
and commit. The workspace then never records a commit that the submodule's
remote lacks, and `push.recurseSubmodules=check` refuses such a push anyway.
With a submodule inside a submodule, the innermost repository comes first and
each pointer is added in the repository around it. Every `git add` names its
paths exactly, relative to the repository it runs in, and no command carries a
comment:

```
git -C projects/field-study add notes/interviews.md
git -C projects/field-study commit -m "Interview notes: the second round"
git -C projects/field-study push
git add projects/field-study logs/decisions.md
git commit -m "Field study: second round recorded"
```

A project marked `Versioned: untracked` has nothing to commit in the workspace;
say so rather than listing its files. A project folder that is a repository of its
own but not a submodule of the workspace commits inside itself only; the workspace
does not `git add` it, which would record an embedded repository, and the report
suggests `/projects:adopt` to make it `own-repo` or `untracked`.

Nothing here commits or pushes on its own; the person runs these, or edits
them first.

## Finally, drop the sentinel

Once all of the above is done, tell the end-of-session capture hook that this
session was closed out, so it writes no redundant draft. Only Claude Code with
this plugin sets `CLAUDE_CODE_SESSION_ID`; elsewhere this does nothing. It is the
one file outside the repository this command touches (the handshake is explained
in the plugin's `docs/DESIGN.md`):

```bash
if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
  d="${CLOSEOUT_DRAFT_ROOT:-$HOME/.claude/closeout-drafts}/$(basename "${CLAUDE_PROJECT_DIR:-$PWD}")"
  mkdir -p "$d" && touch "$d/.closeout-ran.$CLAUDE_CODE_SESSION_ID"
fi
```

## Practices

- **Point rather than restate.** One copy of a fact, and pointers to it, is how a
  record stays true.
- **An honest state beats a hopeful one.** A project marked `blocked`, with what
  blocks it, is visible to the board; one left at `doing` while nothing can
  move is not.
- **Send nothing, and commit no table: it is stale once read.** A message goes out
  in the user's own voice, from them; draft one only when asked. "Nobody in
  particular" is often right; if everyone needs to know, it may be a working
  standard: raise it as a promotion; if nobody can be named, that is a gap in the
  people directory.
- **Keep the axes apart.** Learnings are promoted, tracking is reconciled, and
  who-needs-to-know is suggested. Reported together, the ritual decays into a
  status update.
