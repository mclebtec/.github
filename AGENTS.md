# Agent guidance — `mclebtec/.github`

**`STRUCTURE_ID`:** `github` (see [STRUCTURE_ID](STRUCTURE_ID))

## Purpose

Public org repository of **reusable composite GitHub Actions** and shell scripts for consumer workflows (GCP auth/build, Terraform fmt, env var loading, Helm publish). Consumer repos symlink or reference these via tagged refs — they do not copy action logic.

## Boundaries

- **No** `.cursor/` directory in this repo; org Cursor rules live in private `mclebtec/.cursor` and load via multi-root workspace + `STRUCTURE_ID` in each consumer.
- **No** secrets, API keys, service-account JSON, project IDs, or SA emails committed here. Callers pass values through workflow `secrets.*` / `vars.*` into action **inputs**.
- Scripts read credentials from **environment variables** at runtime only.
- Prefer **Workload Identity Federation (WIF)** for GCP; JSON keys are a documented fallback.

## Safety

- Pin third-party actions by **full commit SHA** in `action.yml` files.
- Pass `${{ inputs.* }}` into bash via step **`env:`**, not interpolated inside `run:` script bodies.
- Workflows in this repo use **minimal** `permissions:`.
- Consumers should reference `mclebtec/.github` by **release tag or SHA**, not a floating `@master`.

## Related docs

- [README.md](README.md) — usage and versioning
- [SECURITY.md](SECURITY.md) — public-repo policy