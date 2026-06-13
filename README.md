# GitHub Actions

Generic reusable composite actions for the `mclebtec` org.

**Public repo — no secrets, no Cursor rules or lint policy.** See [SECURITY.md](SECURITY.md).

## Security

- All secrets are **inputs** from private consumer workflows
- Reusable configs: `config/` (markdown, shell, terraform) — mirrored from private `cursor-rules`
- Never commit `.env`, keys, tokens, or service-account JSON

## Actions (`actions/`)

| Action                                                                                                                 | Purpose                                                                                                                                                                                                                                                                               |
| ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **setup-org-github**                                                                                                   | Checkout `mclebtec/.github` and symlink `actions/` + `scripts/` into `.github/`.                                                                                                                                                                                                     |
| **cursor-lint-docs**                                                                                                   | Prettier `--check` on `**/*.md` using `cursor-lint/` bundle (no consumer vendoring).                                                                                                                                                                                                  |
| **terraform-fmt-check**                                                                                                | `terraform fmt -check -recursive` on a working directory.                                                                                                                                                                                                                             |
| **load-environment-variables**                                                                                         | Merge `vars_json` (workflow `toJson(vars)`) with `environments.<name>` in a repo’s `.github/config/variables.yml`; export to `GITHUB_ENV`. Callers check out `mclebtec/.github` and symlink `actions` → `.github/actions`, then `uses: ./.github/actions/load-environment-variables`. |
| **gcp-auth**, **gcp-build-and-publish**, **gcp-docker-config**, **gcp-maven-config**, **build-and-publish-helm-chart** | GCP / Maven / Helm composites (see each `action.yml`).                                                                                                                                                                                                                                |

### `config/` + `scripts/lint/` (reusable CI)

| Path | Purpose |
| ---- | ------- |
| `config/markdown/` | Prettier — used by **cursor-lint-docs** |
| `config/shell/` | shfmt EditorConfig reference |
| `config/terraform/` | `terraform fmt` EditorConfig reference |
| `scripts/lint/` | `format-markdown.sh`, `format-shell.sh` |
| `scripts/sync-from-cursor-rules.sh` | Mirror configs from private `cursor-rules` |

Author in **`cursor-rules`**, sync to this repo for public CI. See `config/README.md` and
[SECURITY.md](SECURITY.md).

### Available Actions (legacy list — some names may differ from `actions/` above)

1. **detect-module** - Detects Maven module path based on pattern and changed files
2. **generate-version** - Generates version number based on branch and event type
3. **maven-version** - Updates or resets Maven project version
4. **maven-settings** - Configures Maven settings.xml for GCP Artifact Registry
5. **maven-build** - Builds Maven project with optional profiles
6. **maven-deploy** - Authenticates and deploys Maven artifacts to GCP Artifact Registry
7. **docker-build** - Builds and publishes Docker image using Maven
8. **git-tag** - Creates and pushes a Git tag for releases

## Usage in Workflows

Once these actions are in your organization's `.github` repository, reference them like:

```yaml
- name: Detect module
  uses: <org-name>/.github/.github/actions/detect-module@main
  with:
    module_path: ${{ inputs.module_path }}
    module_pattern: ${{ inputs.module_pattern }}
```

Or if using locally in the same repository:

```yaml
- name: Detect module
  uses: ./.github/actions/detect-module
  with:
    module_path: ${{ inputs.module_path }}
    module_pattern: ${{ inputs.module_pattern }}
```

## Migration Guide

To move these actions to organization-level:

1. Copy each action directory to your org `.github` repo:

   ```bash
   cp -r .github/actions/* <org-repo>/.github/actions/
   ```

2. Update workflow files to reference org-level actions:

   ```yaml
   # Change from:
   uses: ./.github/actions/detect-module

   # To:
   uses: <org-name>/.github/.github/actions/detect-module@main
   ```

3. Commit and push to the org repository

## Security Notes

### How Secrets Are Handled

1. **GCP Authentication**: The `maven-deploy` action uses `gcloud auth print-access-token` which
   retrieves a token from the authenticated gcloud session. The GCP service account key is provided
   as a secret in the workflow (via `google-github-actions/auth@v2`), not in the action itself.

2. **GitHub Token**: The `git-tag` action requires a GitHub token, which must be passed as an input
   from the workflow. The workflow should use `secrets.GITHUB_TOKEN` or a custom token secret.

3. **Maven/Docker Registry URLs**: All registry URLs and repository names are passed as inputs,
   never hardcoded.

### Best Practices

- ✅ Store these actions in a public `.github` repository
- ✅ Pass all secrets from the calling workflow
- ✅ Use GitHub secrets for sensitive data
- ✅ Never commit secrets to any repository
- ❌ Don't hardcode credentials in actions
- ❌ Don't log or expose secrets in action outputs

## Benefits

- **Reusability**: Use the same actions across all repositories
- **Maintainability**: Update logic in one place
- **Consistency**: Ensure all repos use the same build process
- **Testability**: Test actions independently
- **Security**: Safe for public repositories - no secrets embedded
