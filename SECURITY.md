# Security — public repository policy

`mclebtec/.github` is **public**. Nothing in this repo may contain secrets, credentials, or
private keys.

## Allowed

- Composite action **inputs** that receive secrets from calling workflows
- References to `secrets.*` / `vars.*` in **documentation only** (never values)
- Public lint/format config (`config/markdown/`, `config/shell/`, `config/terraform/`)
- Scripts that read credentials from **environment variables** at runtime (caller-provided)

## Forbidden

- API keys, tokens, passwords, connection strings, service-account JSON files
- `.env`, `credentials.json`, `*.pem`, `*.p12`, `id_rsa*`
- Hardcoded org secret **values** (names in workflow docs are OK in private consumer repos only)

## Caller responsibility

Consumer workflows (private repos) pass secrets:

```yaml
with:
  workload-identity-provider: ${{ secrets.MY_WIF_PROVIDER }}
  service-account-email: ${{ vars.CI_SA_EMAIL }}
```

## Mirror from `cursor-rules`

Author config in private **`mclebtec/cursor-rules`**, then:

```bash
./scripts/sync-from-cursor-rules.sh
```

Review the diff before push — **never** sync rules, structure manifests, or storage profiles here.

## Report

If you find committed secrets, rotate them immediately and open a private security issue with the
org admin.
