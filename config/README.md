# Reusable configs (public CI mirror)

Lint/format configs mirrored from private **`cursor-rules`**. **No secrets, credentials, or rules**
belong in this public repo — see [SECURITY.md](../SECURITY.md).

| Folder | Tool | CI |
| ------ | ---- | -- |
| `markdown/` | Prettier | `actions/cursor-lint-docs` |
| `shell/` | shfmt EditorConfig | `scripts/lint/format-shell.sh` (local) |
| `terraform/` | `terraform fmt` | `actions/terraform-fmt-check` |

## Not mirrored (private `cursor-rules` only)

`dart/`, `intellij/` — IDE/local tooling; may contain paths unsuitable for a public bundle.

## Sync

```bash
./scripts/sync-from-cursor-rules.sh   # from mclebtec/.github
# or from cursor-rules:
../cursor-rules/scripts/publish-org-github-mirror.sh
```
