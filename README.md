# GitHub Actions

Generic reusable composite actions for the `mclebtec` org.

**Public repo — no secrets or project-specific configuration.** See [SECURITY.md](SECURITY.md) and [AGENTS.md](AGENTS.md).

This repo uses **`STRUCTURE_ID=github`** (no `.cursor/` folder). Org Cursor rules live in private `mclebtec/.cursor`.

## Actions (`actions/`)

| Action | Purpose |
| ------ | ------- |
| **setup-org-github** | Checkout this repo and symlink `actions/` + `scripts/` into consumer `.github/` |
| **terraform-fmt-check** | `terraform fmt -check -recursive` |
| **load-environment-variables** | Merge `variables.yml` + GitHub vars into `GITHUB_ENV` |
| **gcp-auth**, **gcp-build-and-publish**, **gcp-docker-config**, **gcp-maven-config**, **build-and-publish-helm-chart** | GCP / Maven / Helm |

## Usage

Pin a **release tag** or **commit SHA** on `mclebtec/.github` — do not use a floating `@master` in production workflows.

```yaml
# Preferred: org release tag (create tags on this repo when stabilizing a change set)
- uses: mclebtec/.github/actions/terraform-fmt-check@v1
  with:
    working-directory: infra

# Or pin the git SHA of the action path at that tag
- uses: mclebtec/.github/actions/setup-org-github@<full-40-char-sha>
```

After `setup-org-github`, consumer workflows often reference **local** composites under `.github/actions/` (symlinked from this repo). Re-run `setup-org-github` or bump the org ref when upgrading.

### GCP authentication

Prefer **Workload Identity Federation** (`workload-identity-provider` + `service-account-email` from workflow secrets). JSON service-account keys (`gcp-credentials` / `gcp_credentials`) are supported as a fallback only.

Example:

```yaml
- uses: mclebtec/.github/actions/gcp-auth@v1
  with:
    workload-identity-provider: ${{ secrets.GCP_WIF_PROVIDER }}
    service-account-email: ${{ secrets.GCP_SA_EMAIL }}
```

## Security

- Pass secrets via workflow `secrets.*` / `vars.*` into action inputs only
- Never commit `.env`, keys, tokens, or service-account JSON
- Third-party actions inside composites are pinned by commit SHA

## Migration (companion repos)

Org **`org-ruler`** and operational **runbook** content are being reorganized separately from this public actions repo. Consumer workflows should keep using **`mclebtec/.github`** for composites; do not embed org-ruler paths or private runbook identifiers in public workflow YAML. Track breaking action changes via release tags here.