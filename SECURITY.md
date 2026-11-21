# Security — public repository policy

`mclebtec/.github` is **public**. No secrets, credentials, or project-specific configuration belong here.

## Allowed

- Generic composite **actions** (GCP, Terraform fmt, org checkout/link)
- Action **inputs** populated from private workflow `secrets.*` / `vars.*`
- Scripts that read credentials from **environment variables** at runtime
- Pinned third-party action SHAs in composite definitions

## Forbidden

- API keys, tokens, passwords, service-account JSON
- `.env`, `credentials.json`, `*.pem`, `*.p12`, `id_rsa*`
- Hardcoded GCP **project IDs** or **service account emails**
- Project names, private repo references, or unreleased product identifiers

## GCP auth

Use **Workload Identity Federation** in caller workflows when possible. Pass provider and SA email via secrets; reserve JSON keys for legacy or local-only paths.

## Report

Rotate any leaked secret immediately; contact org admin.