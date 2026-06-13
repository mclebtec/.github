# Welcome to mclebtec 👋

We focus on building strong apps and software based on client needs, while also providing reusable GitHub Actions and workflows to streamline CI/CD processes.

## What We Offer

This organization maintains a collection of **composite GitHub Actions** designed for:

- 🏗️ **Org CI setup** — symlink shared actions and scripts into consumer repos
- 📐 **Terraform fmt** — enforce consistent formatting on infrastructure code
- ☁️ **GCP / Maven / Helm** — build, publish, and deploy composites
- 🔐 **Environment loading** — merge profile YAML with GitHub vars for workflows

## Security First

✅ All actions are **safe for public repositories**  
✅ No secrets or credentials hardcoded  
✅ All sensitive data passed from workflows  
✅ GitHub secrets managed at the workflow level  

See [SECURITY.md](https://github.com/mclebtec/.github/blob/master/SECURITY.md) for the full public-repo policy.

## Getting Started

Our reusable actions are available in the [`.github`](https://github.com/mclebtec/.github) repository. Reference them in your workflows:

```yaml
- uses: mclebtec/.github/actions/setup-org-github@master

- uses: mclebtec/.github/actions/terraform-fmt-check@master
  with:
    working-directory: infra
```

Check out our [documentation](https://github.com/mclebtec/.github) for more details on available actions and usage examples.

## Our Mission

We are dedicated to building robust, scalable software solutions tailored to our clients' specific needs. Through automation and best practices, we deliver high-quality applications that drive business value.

---

*Building better software and automation, one solution at a time.* 🚀
