# GitHub Actions

Generic reusable composite actions for the `mclebtec` org.

**Public repo — no secrets, no Cursor rules or lint policy.** See [SECURITY.md](SECURITY.md).

Cursor-specific config and docs lint live in private **`mclebtec/cursor-rules`** only.

## Actions (`actions/`)

| Action | Purpose |
| ------ | ------- |
| **setup-org-github** | Checkout this repo and symlink `actions/` + `scripts/` into consumer `.github/` |
| **terraform-fmt-check** | `terraform fmt -check -recursive` |
| **load-environment-variables** | Merge `variables.yml` + GitHub vars into `GITHUB_ENV` |
| **gcp-auth**, **gcp-build-and-publish**, **gcp-docker-config**, **gcp-maven-config**, **build-and-publish-helm-chart** | GCP / Maven / Helm |

## Usage

```yaml
- uses: mclebtec/.github/actions/terraform-fmt-check@master
  with:
    working-directory: primecare-infra

- uses: mclebtec/.github/actions/setup-org-github@master
```

Docs lint (Prettier) — checkout private `cursor-rules` in the consumer workflow and run
`./scripts/lint-docs.sh` (see `cursor-rules/config/ci/README.md`).

## Security

- Pass secrets via workflow `secrets.*` / `vars.*` into action inputs only
- Never commit `.env`, keys, tokens, or service-account JSON
