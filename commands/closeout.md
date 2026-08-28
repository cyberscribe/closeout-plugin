---
description: Capture session learnings into durable in-repo docs and prepare to close out
---

Review what was learned or decided this session, then update any durable **in-repo**
documentation it warrants. Make surgical updates only — never a full rewrite of an
existing doc.

Default targets, unless this project's conventions say otherwise:

- The project's documentation directory (`docs/`, or wherever it keeps durable reference)
- `docs/DECISIONS.md` — architectural and structural decisions

If `.claude/closeout.md` exists in this project, read it first: it names this team's
own doc destinations and house rules, and it overrides the defaults above.

A learning is worth recording if a future agent would otherwise re-derive it.

Prefer committed, team-visible destinations. A note left in a gitignored scratch
directory or a personal memory file reaches nobody else — if a teammate would
benefit from it, it has to land somewhere committed.

Before recording any technical claim, verify it against the current code — do not
document a bug or behaviour that has since changed during this session.

Then prepare to close out:

- Confirm any task/tracking files this project keeps reflect reality.
- Release any locks or claims this session holds.
- Briefly summarise what was changed and flag any critical items remaining.

Finally — and only after the above is genuinely done — signal that this session
has been closed out, so the automatic end-of-session capture hook does not write a
redundant draft on top of the work you just promoted. Drop a one-shot,
**per-session** sentinel (the only out-of-repo file this command touches):

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
