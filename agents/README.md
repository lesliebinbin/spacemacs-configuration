# Agent Assets

This directory is the source of truth for reusable agent material used from the
Spacemacs environment.

## Layout

```text
agents/
├── hooks/       # Runtime-specific lifecycle integrations
├── profiles/    # Reusable roles and engineering defaults
├── runbooks/    # Agent-independent, repeatable procedures
└── skills/      # Task-triggered capabilities and their local resources
```

## Responsibilities

- A **runbook** is the smallest procedural unit. It records prerequisites,
  steps, expected results, verification, and recovery guidance.
- A **skill** decides when and how an agent should apply one or more runbooks.
  It may also include templates, scripts, and technical references.
- A **profile** supplies reusable priorities and defaults for a class of work.
- A **hook** is executable integration invoked by a host lifecycle event. Hooks
  are runtime-specific and must not be treated as documentation.

Skills should be directories so they can gain `references/`, `scripts/`, and
`templates/` without changing their public name. Keep broadly reusable
procedures in `runbooks/`; keep skill-specific supporting material inside the
skill.

This location is organizational. Agent runtimes must be configured explicitly
to discover or install assets from it.