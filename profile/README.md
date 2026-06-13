# Welcome to mclebtec 👋

We focus on building strong apps and software based on client needs, while also providing reusable GitHub Actions and workflows to streamline CI/CD processes.

## What We Offer

This organization maintains a collection of **composite GitHub Actions** designed for:

- 🔍 **Module Detection** - Automatically detect Maven modules based on changes
- 📦 **Version Management** - Generate and manage semantic versions
- 🏗️ **Maven Builds** - Build and deploy Maven projects
- 🐳 **Docker Publishing** - Build and publish Docker images
- 🏷️ **Git Tagging** - Automated release tagging

## Security First

This org’s **public** [`.github`](https://github.com/mclebtec/.github) repo holds only reusable
actions and lint config — **no secrets, credentials, or private rules**.

- Secrets stay in **private consumer workflows** (`secrets.*`, `vars.*`)
- Config is mirrored from private `cursor-rules` via `publish-org-github-mirror.sh`  

## Getting Started

Our reusable actions are available in the `.github` repository. Reference them in your workflows:

```yaml
- name: Detect module
  uses: mclebtec/.github/.github/actions/detect-module@main
```

Check out our [documentation](https://github.com/mclebtec/.github) for more details on available actions and usage examples.

## Our Mission

We are dedicated to building robust, scalable software solutions tailored to our clients' specific needs. Through automation and best practices, we deliver high-quality applications that drive business value.

---

*Building better software and automation, one solution at a time.* 🚀

