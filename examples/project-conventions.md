# Example `.claude/closeout.md`

Copy this to `.claude/closeout.md` in a consuming project and rewrite it for your
team. Both `/closeout` and the automatic capture hook read it verbatim and follow
it, overriding the plugin defaults.

Keep it prose. There is no schema — it is appended to a prompt.

---

Doc destinations for this project, in priority order:

- `docs/` — durable reference, one file per subsystem. Surgical edits only; never
  rewrite a file wholesale.
- `docs/DECISIONS.md` — architectural and structural decisions, newest first, with
  the date and the alternative that was rejected.
- `ai/Memory/` — shared cross-role working notes. **Gitignored**: fine for
  in-flight context, wrong for anything a teammate needs.
- `ai/Tracking/{role}/` — per-role TODO/DOING/DONE queues.

House rules:

- Only `docs/` is committed and therefore team-visible. If a learning would help a
  teammate, it has to land there — a note in `ai/` or in personal agent memory
  reaches nobody.
- Convert relative dates to absolute before writing ("last Tuesday" rots).
- Before closing: confirm `ai/Tracking/{role}/DOING.tsv` reflects reality (finished
  work to DONE, abandoned work back to TODO), and release any locks held in
  `ai/Memory/LOCKS.md`.
