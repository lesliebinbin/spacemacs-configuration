# Hooks

Hooks are executable integrations triggered by lifecycle events from a
specific host, such as Emacs or an agent runtime.

Group future hooks by host:

```text
hooks/
├── emacs/
├── copilot-cli/
└── shared/
```

Every hook should document:

- its triggering event and input schema;
- commands, files, or network resources it may access;
- user-confirmation requirements;
- timeout and failure behavior; and
- cleanup and idempotency guarantees.

Do not add a hook when a runbook or skill is sufficient. Nothing in this
directory should execute merely because an agent reads it.
