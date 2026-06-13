# Security — public repository policy

`mclebtec/.github` is **public**. No secrets, credentials, or project-specific configuration belong here.

## Allowed

- Generic composite **actions** (GCP, Terraform fmt, org checkout/link)
- Action **inputs** populated from private workflow `secrets.*` / `vars.*`
- Scripts that read credentials from **environment variables** at runtime

## Forbidden

- API keys, tokens, passwords, service-account JSON
- `.env`, `credentials.json`, `*.pem`, `id_rsa*`
- Project names, private repo references, or unreleased product identifiers

## Report

Rotate any leaked secret immediately; contact org admin.
