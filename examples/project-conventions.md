# Example `.claude/closeout.md`

Copy this to `.claude/closeout.md` in a consuming project and rewrite it for your
team. Both `/closeout` and the automatic capture hook read it verbatim and follow
it, overriding the plugin defaults.

Keep it prose. There is no schema — the file is appended to a prompt.

## Two levels of override

**Moving destinations** — you like the four default tiers but your files live
elsewhere. Do not write a conventions file at all; set environment variables under
`"env"` in `.claude/settings.json`:

```json
"env": {
  "CLOSEOUT_TIER_ALWAYS": "GUIDELINES.md",
  "CLOSEOUT_TIER_GENERAL": "handbook/",
  "CLOSEOUT_TIER_PROJECT": "docs/, docs/DECISIONS.md",
  "CLOSEOUT_TIER_TEMPLATES": ".claude/agents/"
}
```

**Replacing the taxonomy** — you want different tiers, different names, a different
number of them, or different load rates. Give this file a `## Promotion tiers`
heading. The plugin detects that heading and suppresses its own table entirely, so
the prompts never carry two competing tier lists. Your section is then the only
taxonomy in play, and the environment variables above are ignored.

Everything below the line is the example itself.

---

# Closeout conventions

## Promotion tiers

| Tier | Loaded back | Shared destination | Individual destination |
|---|---|---|---|
| Standing rules | ALWAYS — every session | `CLAUDE.md` | `~/.claude/CLAUDE.md` |
| Playbooks | when the matching task starts | `handbook/` | — |
| Service reference | when that service is being worked on | `docs/services/<name>.md` | — |
| Decisions | on demand, and read before proposing an approach | `docs/DECISIONS.md` | — |
| Scratch | never loaded; working notes only | — | `~/.claude/projects/<p>/memory/` |

Choose the cheapest tier that works. Standing rules cost every future session, so
an addition there must name the line it replaces — we hold that file under 120
lines deliberately.

## House rules

- Surgical edits only. Never rewrite an existing doc wholesale.
- Convert relative dates to absolute before writing. "Last Tuesday" rots.
- Verify every technical claim against current code before recording it.
- One claim per entry, with the reason it is true, not just the assertion.
- `handbook/` and `docs/` are committed; anything under `~/.claude/` reaches
  nobody but you, so never leave a team-relevant learning there.

## Before closing out

- Move finished work to DONE and return abandoned work to TODO in the tracker.
- Release any locks this session holds.
- Report which tier each promoted item landed in.
