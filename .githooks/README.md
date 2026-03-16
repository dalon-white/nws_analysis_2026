# .githooks/

Optional git hooks (scripts triggered by git events).

Enable with:

```bash
git config core.hooksPath .githooks
```

Disable with:

```bash
git config --unset core.hooksPath
```

> **What’s a git hook?** A lightweight script Git runs at moments like *pre-commit* or *pre-push*. This template’s hook simply prints a reminder; it does **not** block pushes.
