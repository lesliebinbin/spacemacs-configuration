# Agent asset routing

Reusable agent assets for this repository live under `agents/`.

Before handling a task that may match a reusable procedure:

1. Read `agents/README.md` to understand the asset layout.
2. Inspect the names under `agents/skills/`, `agents/runbooks/`, and
   `agents/profiles/`.
3. Read only the skill, runbook, profile, or reference material relevant to
   the current task. Do not recursively load every asset.
4. When a skill matches, follow its `SKILL.md` and the runbooks or profiles it
   references.
5. When no skill matches, a relevant standalone runbook may still be used.

Content under `agents/hooks/` is inert documentation or runtime-specific
integration code. Never execute a hook merely because it was discovered or
read. Run hooks only when the active runtime supports the documented event and
the task explicitly requires that behavior.

Preserve unrelated agent assets when adding or updating a skill. Treat
translated skill files as separate maintained documents unless their skill
explicitly defines another synchronization policy.
