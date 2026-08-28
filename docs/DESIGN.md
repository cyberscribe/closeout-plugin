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
retention window as a backstop.

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
- `--add-dir` restricted to the transcript's directory and the draft directory.
- Prompted explicitly to write only the scratch file, never in-repo docs.
- `--permission-mode acceptEdits` — safe only *because* of the two bounds above.

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

## Extension via `.claude/closeout.md`

Teams have their own closeout rules — a tracking queue to reconcile, locks to
release, a house style for doc edits. Encoding those as plugin configuration
means inventing a schema that will never fit the next team.

Instead, an optional `.claude/closeout.md` in the consuming project is read
verbatim by both the command and the capture prompt. Prose in, prose out. It costs
one file check and covers arbitrary conventions.

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
