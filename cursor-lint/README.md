# cursor-lint (public CI bundle)

Public mirror of lint config from private `mclebtec/cursor-rules` for GitHub Actions.

Consumer workflows check out **`mclebtec/.github`** (public — no PAT) and run scripts here.
Local dev still uses sibling `../cursor-rules`.

When updating Prettier or shfmt rules in `cursor-rules`, sync this folder before CI will pass.

```bash
# From cursor-rules repo root
rsync -a config/markdown/ ../.github/cursor-lint/config/markdown/
rsync -a config/shell/ ../.github/cursor-lint/config/shell/
```
