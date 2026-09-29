# Design notes

Background for anyone modifying the plugin. The README covers use; this covers
why it is shaped the way it is.

## The constraint that determines the architecture

Claude Code hooks differ in one decisive way: whether their output reaches an
active agent.

| Hook | Fires | Can inject context? |
|---|---|---|
| `SessionStart` | before the agent loop | **yes** (`additionalContext`) |
| `UserPromptSubmit` | before each turn | **yes** |
| `SessionEnd`, `PreCompact` | after the agent loop has exited | **no** |

Capture has to happen at session end — that is when the transcript is complete.
But nothing at session end can talk to an agent, because there is no longer an
agent. So capture spawns its own headless `claude -p`, and the *result* is
surfaced one session later through `SessionStart`, the earliest point where
injection is possible again.

Everything else follows from that split: the draft file exists because capture
and review happen in different processes, hours or days apart.

## Why drafts live outside the repo

`~/.claude/closeout-drafts/<project-basename>/<session-id>.md`

- Never committed by accident — a half-formed automated note is not team content.
- Per-user: your forgotten sessions are your business.
- Survives reboots, unlike `/tmp`.
- Keyed by project so a draft only nudges in the repo it came from.

The cost is that the directory sits outside a sandboxed session's writable set,
which is why the README asks for an `allowWrite` entry: otherwise the agent can
read a draft and promote it but never delete it, and the same draft nudges
forever. `closeout-review.sh` runs unsandboxed and prunes drafts past the
retention window as a backstop. Retention counts from the first session that
surfaced the draft, recorded by a `.seen.<draft>` marker, never from capture time:
a draft written before a week away is still waiting after it, and only a draft
that has been offered and left for the window is pruned.

## The sentinel handshake

`/closeout` and the capture hook can both fire for the same session. If both run,
the draft duplicates work the agent already did properly, with full context —
strictly worse output, and it nags on the next session.

So `/closeout` writes `.closeout-ran.<session-id>` into the draft directory, and
the capture hook consumes exactly the sentinel matching the ending session, then
skips.

**Keying by session id, not project, is load-bearing.** An earlier version used a
single bare `.closeout-ran` per project. With concurrent sessions or git
worktrees, the first session to end consumed the shared sentinel and every other
session wrote a spurious draft. Per-session keying means a closeout in one session
suppresses only that session's capture; the others keep their safety net.

A sentinel older than 6h is cleared but **not** honored, so a closeout followed by
a long-running session can never mute captures indefinitely.

## Blast radius of the capture child

The child is an unattended agent run triggered by exiting a session. That deserves
tight bounds:

- `--allowedTools "Read,Write"` — no Bash, no network.
- It runs from the draft directory, so writes to the repository fall outside the
  directories `acceptEdits` approves unprompted, and a headless run has nobody to
  approve them. `--add-dir` adds to the working directory rather than
  restricting it; spawned from the project, the whole repo would be approved.
- The transcript's directory is the one grant beyond the draft directory. It
  holds the project's other transcripts and, for Claude Code, its `memory/`
  folder; the child is prompted to write only its scratch file, and that part of
  the bound is prompt-enforced.
- The review hook exits at once inside the child (`CLOSEOUT_HOOK_CHILD`), so the
  child is never told to surface drafts to a user it does not have.
- `--permission-mode acceptEdits` — scoped by the working directory above; the
  transcript-directory write is prompt-enforced.

Promotion into real documentation happens later, interactively, with a human
approving. The unattended half of the system can only ever produce a file in a
scratch directory.

## The recursion guard

The capture child is itself a Claude Code session, so it triggers `SessionEnd` on
exit — which would spawn another child, forever. `CLOSEOUT_HOOK_CHILD=1` is set on
the child's environment and the script early-exits when it sees it.

This is the single most important line in the plugin. Do not remove it.

## Detaching

`setsid nohup … &` is the clean detach, but `setsid` is not on stock macOS (only
via MacPorts or Homebrew) and is frequently missing from the stripped PATH a hook
runs under. `nohup … & disown` is the fallback and survives parent exit on any
POSIX shell. Both are used; presence decides which.

The detach matters for a mundane reason: without it, quitting Claude Code would
block for the 20–40s the child's API call takes.

## Why promotion is tiered

The first version promoted into one undifferentiated bucket: "durable docs". That
answers *is this worth keeping?* and stops there, which is the wrong question to
stop on.

What actually costs something is not storage, it is **load rate**. A note in an
always-loaded file is paid for by every future session in that project, forever,
whether or not it is relevant to the task at hand. A note in a reference file that
loads on demand costs nothing until something asks for it. Those are different
decisions by orders of magnitude, and a flat destination list hides the difference.

So promotion classifies on two axes:

- **Tier** — how often it is loaded back. Four by default: always-loaded working
  standards, cross-project general reference, per-project reference, and templates
  or agent role definitions.
- **Scope** — shared (committed, reaches teammates) or individual (one machine,
  one user). A learning a teammate needs is worthless in an individual destination,
  and this is the axis people get wrong most often.

The rule that makes the taxonomy do work rather than just describe things:
**promotion into the always-loaded tier is zero-sum.** It must name what it
displaces or justify the budget growing; every other tier is additive. Without
that, an always-on file only ever grows — each individual addition is defensible,
the aggregate is not, and nobody is ever in the room where the aggregate is
decided. A capture-and-promote loop makes that erosion faster, not slower, which
is exactly why the loop needs the constraint.

The agent is also told to default to the cheapest tier that works. The bias has to
be explicit, because "put it where it will definitely be seen" is the locally
rational choice every time.

## Two levels of override, and why not a schema

Teams disagree about tiers. Some want three, some want six, some already have a
vocabulary ("playbooks", "runbooks", "standing orders") that a plugin has no
business renaming.

Encoding that as configuration means inventing a schema — tier objects with names,
load rates, destination globs, scope mappings — that will not survive contact with
the third team to adopt it.

So there are two levels instead:

- **Destinations move by environment variable** (`CLOSEOUT_TIER_ALWAYS` and
  friends). Keeps the default four tiers, points them at your files. One line each
  in `.claude/settings.json`, no file to write.
- **The taxonomy is replaced by prose.** A `## Promotion tiers` heading in
  `.claude/closeout.md` and the plugin's own table is suppressed entirely — both
  prompts then carry the project's section and nothing else. Detection is a single
  `grep -qiE` for the heading.

The suppression matters more than it looks. An earlier shape appended the project
table *after* the default one, and the model had to reconcile two tier lists that
disagreed; it split the difference roughly half the time. A taxonomy is not
additive. Either the plugin's applies or the project's does.

## Who needs to know, and why the hook computes the team

A learning promoted into a file nobody knows has changed reaches nobody until
they happen to open it. So when a project names two or more people, the closeout
ends with a short "who needs to know" table.

Three choices shape it:

- **The team is computed by the hook, not the child.** The capture child runs from the
  draft directory and cannot see the repository's people directory from there. `lib/config.sh` resolves the list and passes it in.
- **It is advice, not delivery.** Nothing is sent. A message to a colleague goes
  out in a person's own voice; an unattended agent writing to someone's
  colleagues on exit is the wrong blast radius entirely.
- **It never reaches the repository.** It is communication — a third axis beside
  context and tracking — and it goes stale as soon as it is read.

## Extension via `.claude/closeout.md`

Teams have their own closeout rules — a tracking queue to reconcile, locks to
release, a house style for doc edits. Encoding those as plugin configuration
means inventing a schema that will never fit the next team.

Instead, an optional `.claude/closeout.md` in the consuming project is read
verbatim by both the command and the capture prompt. Prose in, prose out. It costs
one file check and covers arbitrary conventions — including replacing the
promotion taxonomy outright, as above.

## A personal layer, and why the project wins

Some conventions belong to a person rather than a team: a destination only they
use (learnings about a tool they maintain, routed to its own repository), a line
they want in every report. Written into each project's `.claude/closeout.md`, they
would leak one person's habits into every team they work with. So there is a
second file, `~/.claude/closeout.md`, read by the command, appended to the capture
prompt and named in the review reminder.

Precedence is project, then person, then plugin defaults. The project wins because
it is shared: a teammate closing out in the same repository must get the same
answer about where a learning goes, and a personal file they cannot see must not
change that. The personal file still outranks the defaults, because the defaults
are only a guess made without knowing either. Tiers follow the same order: a
personal `## Promotion tiers` section replaces the default table only in projects
that define no tiers of their own. Team detection ignores the personal file —
who is on a project is the project's to say.

The capture child sees both files as text in one prompt, with no way to tell which
came from where, so the prompt says the precedence in words rather than relying on
order alone. `CLOSEOUT_USER_CONVENTIONS` exists so the tests, and anyone
debugging, can point the hooks at a known file or at none.

## Tracking, reconciled after the learnings

`/closeout` ends by bringing the project's tracking up to date — ticking its Done
when list and refreshing the Current state block: its state, its `Blocked by:`
line, its date and the dated line that says where the work stands. It is a
separate step, reported separately, because context and tracking are different
axes: merged, the closeout becomes a status update and the learnings stop being
recorded. Tracking is reconciled but never invented. The state moves only when
the session plainly moved it, and a blocker is written down with the date it
began, so the projects board can flag one that has lasted too long; adding a
missing Current state block, converting an older block, pausing a project or
marking it done are left to the person and the projects commands that own them. The capture child
does none of this: it cannot read the repository, and tracking changed
unattended is tracking nobody trusts.

## Troubleshooting

**No drafts ever appear.**

1. Confirm the hooks are approved — `/hooks` lists what is active. An unapproved
   plugin's hooks silently never run.
2. Confirm `jq` and `claude` resolve in a minimal environment:
   `env -i bash -c 'command -v jq claude'`. If `claude` is missing, set
   `CLOSEOUT_CLAUDE_BIN`.
3. Remember the skip conditions: `/clear` exits, transcripts under
   `CLOSEOUT_MIN_LINES`, and sessions where the child judged nothing durable
   happened. All three are correct behaviour.

**To see what the hook actually did**, run it by hand against a real transcript:

```bash
echo '{"reason":"exit","transcript_path":"<path>","session_id":"manual-test","cwd":"'"$PWD"'"}' \
  | bash hooks/closeout-capture.sh
```

Then watch `~/.claude/closeout-drafts/<basename>/manual-test.md` appear (or not)
over the next minute.

**A draft nudges every session and never goes away.** The agent could not delete
it — check the `Bash(rm *closeout-drafts*)` permission and the sandbox
`allowWrite` entry, and note that a sandbox change needs a fresh session.
