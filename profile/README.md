# Welcome to mclebtec 👋

We build client software and maintain **generic** reusable GitHub Actions in the public
[`.github`](https://github.com/mclebtec/.github) repo.

## Public `.github` (generic CI)

- `setup-org-github`, `terraform-fmt-check`, GCP/Maven/Helm composites
- **No** Cursor rules, Prettier policy, or secrets

## Private `cursor-rules` (Cursor + lint policy)

- Rules, `STRUCTURE_ID`, `config/markdown|shell|terraform`
- Docs lint in CI: checkout `cursor-rules` from consumer `build.yml`

```yaml
- uses: mclebtec/.github/actions/terraform-fmt-check@master
- uses: mclebtec/.github/actions/setup-org-github@master
```

See [SECURITY.md](https://github.com/mclebtec/.github/blob/master/SECURITY.md).
