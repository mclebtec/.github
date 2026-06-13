# cursor-lint

Canonical **CI lint bundle** in `mclebtec/.github`. Mirrors `cursor-rules/config/markdown/` and
`config/shell/` for workflows that cannot access the private `cursor-rules` repo.

## Consumer usage (composite action — preferred)

```yaml
- uses: mclebtec/.github/actions/cursor-lint-docs@master
```

No vendored copy in consumer repos. Local dev still uses sibling `../cursor-rules`.

## Sync from cursor-rules

```bash
cd cursor-rules
rsync -a config/markdown/ ../.github/cursor-lint/config/markdown/
rsync -a config/shell/ ../.github/cursor-lint/config/shell/
```

## Scripts

| Script | Purpose |
| ------ | ------- |
| `scripts/format-markdown.sh` | Prettier format/check |
| `scripts/format-shell.sh` | shfmt format/check (local / optional) |
