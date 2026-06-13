# GitHub Actions

Generic reusable composite actions for the `mclebtec` org.

**Public repo — no secrets or project-specific configuration.** See [SECURITY.md](SECURITY.md).

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
    working-directory: infra

- uses: mclebtec/.github/actions/setup-org-github@master
```

## Security

- Pass secrets via workflow `secrets.*` / `vars.*` into action inputs only
- Never commit `.env`, keys, tokens, or service-account JSON
