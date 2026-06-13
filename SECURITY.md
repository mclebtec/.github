# Security — public repository policy

`mclebtec/.github` is **public**. No secrets, credentials, Cursor rules, or lint policy configs
belong here.

## Allowed

- Generic composite **actions** (GCP, Terraform fmt, org checkout/link)
- Action **inputs** populated from private workflow `secrets.*` / `vars.*`
- Scripts that read credentials from **environment variables** at runtime

## Forbidden

- Cursor rules, `STRUCTURE_ID` manifests, Prettier/shfmt policy tied to Cursor workflows
- API keys, tokens, passwords, service-account JSON
- `.env`, `credentials.json`, `*.pem`, `id_rsa*`

## Where Cursor config lives

Private **`mclebtec/cursor-rules`** only. Consumer CI checks out `cursor-rules` for docs lint;
generic steps use `mclebtec/.github/actions/*`.

## Report

Rotate any leaked secret immediately; contact org admin.
