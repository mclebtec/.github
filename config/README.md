# Reusable configs (CI)

Public copies of lint/format config used by **composite actions** and consumer `build.yml` workflows.
**Do not duplicate** these in consumer repos.

| Folder | Tool | Action / script |
| ------ | ---- | ---------------- |
| `markdown/` | Prettier | `actions/cursor-lint-docs`, `scripts/lint/format-markdown.sh` |
| `shell/` | shfmt | `scripts/lint/format-shell.sh` (local/optional) |
| `terraform/` | `terraform fmt` | `actions/terraform-fmt-check` |

## Not here (local dev only — private `cursor-rules`)

| Folder | Reason |
| ------ | ------ |
| `dart/` | Flutter analyzer — local IDE/CI in app repo |
| `intellij/` | Java IDE scheme — not needed in public CI bundle |

## Sync from cursor-rules

```bash
./scripts/sync-from-cursor-rules.sh
```

Or manually:

```bash
rsync -a ../cursor-rules/config/markdown/ config/markdown/
rsync -a ../cursor-rules/config/shell/ config/shell/
rsync -a ../cursor-rules/config/terraform/ config/terraform/
```

Canonical authoring: **`mclebtec/cursor-rules`** (`rules-setup`). This repo is the **public CI mirror**.
