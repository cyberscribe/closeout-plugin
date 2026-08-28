# closeout — a documentation safety net for Claude Code

Sessions end and their learnings evaporate. The decision you made, the constraint
you discovered, the state of the half-finished work — all of it lives in a
transcript nobody will read again.

The habit that fixes this is asking the agent to *"review what you learned and
update the docs"* before you close. The habit works. People forget it.

This plugin makes the habit explicit (`/closeout`) and adds a backstop for when
you forget: on session end a detached headless agent reads the transcript and
writes candidate doc-notes to a draft outside the repo; on your next session in
that project the agent surfaces the draft and offers to promote it.

It is **not** a replacement for updating docs during real work. It is the net
under the sessions where the ritual was skipped.

## Install

```
/plugin marketplace add cyberscribe/closeout-plugin
/plugin install closeout@closeout-marketplace
```

Or from a local checkout:

```
/plugin marketplace add /path/to/closeout-plugin
/plugin install closeout@closeout-marketplace
```

To pin it for a whole team instead, commit this to the repository's
`.claude/settings.json` — teammates get the source without running anything:

```jsonc
{
  "extraKnownMarketplaces": {
    "closeout-marketplace": {
      "source": { "source": "github", "repo": "cyberscribe/closeout-plugin" }
    }
  },
  "enabledPlugins": { "closeout@closeout-marketplace": true }
}
```

Vendoring it as a git submodule works too — point the source at the checkout
directory rather than GitHub:

```jsonc
{
  "extraKnownMarketplaces": {
    "closeout-marketplace": {
      "source": { "source": "directory", "path": ".claude/plugins/closeout" }
    }
  },
  "enabledPlugins": { "closeout@closeout-marketplace": true }
}
```

That pins the exact commit in your repo's history and needs no network at
install time, at the cost of a `git submodule update --init` on clone.

Claude Code gates hooks behind a trust prompt. **Approve them once when asked** —
if you don't, the hooks silently never run and you get `/closeout` only.

## How it works

| Part | What it does |
|------|--------------|
| `/closeout` command | A saved prompt. Type it before ending a session and the agent reviews learnings and updates durable docs **live, with full context** — the highest-quality path. |
| Capture hook (`SessionEnd`) | Spawns a **detached, sandboxed** headless `claude -p` that reads the just-ended transcript and writes candidate notes to a draft file outside the repo. The automatic backstop. |
| Review hook (`SessionStart`) | If drafts exist, injects a reminder instructing the agent to surface them first-thing and offer to promote — verify each claim against current code, then promote and delete the draft, only with your go-ahead. Never silently. |

```
session ends ──▶ SessionEnd ──▶ closeout-capture.sh
                                  └─▶ detached `claude -p` reads transcript,
                                      writes draft (only if something durable)
                                         │
next session starts ──▶ SessionStart ──▶ closeout-review.sh
                                  └─▶ injects "pending draft" reminder
                                         │
                         agent promotes durable items into docs, deletes draft
```

Drafts live at `~/.claude/closeout-drafts/<project-basename>/<session-id>.md` —
deliberately outside the git repo: never committed by accident, per-user, and
persistent across reboots.

## Required project setup

Two things the plugin cannot do for you, because a plugin cannot edit your
settings. Add them to the consuming project's `.claude/settings.json`:

```jsonc
{
  "permissions": {
    "allow": [
      // Lets the agent delete a draft after promoting it, without a prompt.
      // `rm` everywhere else still prompts.
      "Bash(rm *closeout-drafts*)"
    ]
  },
  "sandbox": {
    "filesystem": {
      // Only needed if you run with the sandbox enabled. The draft directory is
      // outside the default writable set, so without this the in-session agent
      // can read a draft but never delete it.
      "allowWrite": ["~/.claude/closeout-drafts"]
    }
  }
}
```

A copy-paste version is in [`examples/settings.snippet.json`](examples/settings.snippet.json).

A `sandbox.allowWrite` change only takes effect in a **newly started** session,
not the one in which you edited it.

## Configuring it

Zero configuration required. The plugin auto-detects your docs directory
(`docs/` → `doc/` → `documentation/` → repo root).

**Per-project conventions.** If your team has its own closeout rules — extra
tracking files, a role-scoped work queue, a house style for doc edits — write
them in `.claude/closeout.md`. Both the `/closeout` command and the capture hook
read that file and follow it, and it overrides the defaults. This is the intended
extension point; there is no config schema to learn. See
[`examples/project-conventions.md`](examples/project-conventions.md).

**Environment variables**, set under `"env"` in the project's `.claude/settings.json`:

| Variable | Default | Purpose |
|---|---|---|
| `CLOSEOUT_DISABLED` | unset | `1` disables both hooks, leaving `/closeout` alone. |
| `CLOSEOUT_MODEL` | `sonnet` | Model for the capture child. `haiku` is cheaper. |
| `CLOSEOUT_DOC_DIR` | auto-detected | Documentation directory, repo-relative. |
| `CLOSEOUT_DECISIONS_FILE` | `<doc dir>/DECISIONS.md` | Where architectural decisions are logged. |
| `CLOSEOUT_DOC_TARGETS` | derived | Free-text override for the destinations named in prompts. |
| `CLOSEOUT_MIN_LINES` | `6` | Transcript lines below which a session is too trivial to capture. |
| `CLOSEOUT_DRAFT_ROOT` | `~/.claude/closeout-drafts` | Where drafts are kept. |
| `CLOSEOUT_DRAFT_RETENTION_DAYS` | `3` | Age at which an unpromoted draft is pruned. |
| `CLOSEOUT_CLAUDE_BIN` | auto-detected | Explicit path to the `claude` binary. |

## Dependencies

Resolved against a minimal hook environment, not your shell:

- **`jq`** — required. Ships with macOS; `apt install jq` / `brew install jq` elsewhere.
- **`claude`** — the capture script probes `command -v`, then `~/.local/bin/claude`,
  then `/usr/local/bin/claude`. Set `CLOSEOUT_CLAUDE_BIN` if yours is elsewhere.
- **`nohup`** — required (system).
- **`setsid`** — *optional*. Used for a clean detach when present; **not on stock
  macOS**. Falls back to `nohup … & disown`, which works without it.

## Cost

Each non-trivial session close spawns one headless run billed to your account.
`sonnet` by default; set `CLOSEOUT_MODEL=haiku` to reduce it, or
`CLOSEOUT_DISABLED=1` to keep only the manual `/closeout`.

## Security posture

The capture child is deliberately boxed in:

- `--allowedTools "Read,Write"` — no Bash, no network tools.
- `--add-dir` limited to exactly the transcript's directory (read) and the draft
  directory (write). It cannot touch your repo, your settings, or other projects.
- It is told explicitly not to edit any in-repo documentation — only the scratch file.

Promotion into real docs always happens in a normal, interactive session with
your approval.

## Known limitations & gotchas

- **Reopen race (benign).** Close and *immediately* reopen and the new session's
  `SessionStart` can run before the detached child has finished writing (it makes
  an API call, ~20–40s). The draft is caught on the *following* session, not lost.
- **Trivial sessions are skipped.** `/clear` exits and very short transcripts are
  ignored, and the child is told to write nothing if no durable learning occurred.
  An empty drafts directory therefore means either "hook didn't fire" or "fired
  and correctly found nothing" — see [Troubleshooting](docs/DESIGN.md#troubleshooting)
  to tell them apart.
- **Recursion guard.** The capture child would itself trigger `SessionEnd` on exit;
  the script early-exits when `CLOSEOUT_HOOK_CHILD` is set. Do not remove that guard.
- **Project keying is by directory basename.** Two checkouts with the same
  basename share a draft directory. Set `CLOSEOUT_DRAFT_ROOT` per checkout if that
  bites you.
- **Drafts can be stale or wrong.** They are written by an automated pass over a
  transcript. The review prompt insists on verifying each claim against current
  code before promotion — a bug the draft describes may already be fixed.

## Why a detached child, and not the agent itself

`SessionEnd` (and `PreCompact`) hooks fire *after* the agent loop has exited, and
their stdout is **not** injected into the conversation — so the just-ended agent
cannot be made to do the capture. Only `SessionStart` and `UserPromptSubmit` hooks
can inject text an active agent sees (that is how the review hook works). Hence
capture must spawn its own headless run.

Design notes and the full rationale: [`docs/DESIGN.md`](docs/DESIGN.md).
