# McLebTec

**[mclebtec.com](https://mclebtec.com)** · United Kingdom

McLebTec is an umbrella tech company building products across **Communications**, **Healthcare**, and **Finance**. We ship focused applications and the shared platform that runs them.

---

## Products

### PrimeCare — Healthcare

One stop solution for all healthcare problems.

Patient and specialist mobile workflows (Flutter), Vue web admin, and a Spring Boot Modulith domain API — covering discovery, booking, facility/specialist journeys, and billing integrations.

- App: [mclebtec/primecare](https://github.com/mclebtec/primecare)
- Backend: [mclebtec/primecare-domain](https://github.com/mclebtec/primecare-domain)

### Flexcomms — Communications

Node.js / TypeScript application for template viewing and printing.

Create HTML templates with `{{placeholder}}` syntax, manage them through an Express + Prisma API and React webapp, and store assets in local or GCP Cloud Storage.

- [mclebtec/flexcomms](https://github.com/mclebtec/flexcomms)

### FinSight — Finance

AI financial assistant for the UK.

- [mclebtec/finsight](https://github.com/mclebtec/finsight)

---

## Engineering / platform

Shared infrastructure and delivery tooling used across products:

| Repo | Role |
| ---- | ---- |
| [mc-infra](https://github.com/mclebtec/mc-infra) | GCP infrastructure as code (Terraform): GKE, Cloud SQL, Secret Manager, Artifact Registry, VPC |
| [mc-common-helm](https://github.com/mclebtec/mc-common-helm) | Shared Helm charts for data services, presentation APIs, and gateway |
| [mc-spring-common](https://github.com/mclebtec/mc-spring-common) | Reusable Spring Boot packages published to Maven |
| [mc-primecare-deploy](https://github.com/mclebtec/mc-primecare-deploy) | Helm / GKE deploy automation for Primecare |
| [runbook](https://github.com/mclebtec/runbook) | Primecare / GCP bootstrap scripts and workflow wrappers |
| [.github](https://github.com/mclebtec/.github) | Org composite GitHub Actions and CI helpers |

Marketing site source: [mclebtec/mclebtec-ui](https://github.com/mclebtec/mclebtec-ui).

---

## Coming soon

Early repos in the org (not launch products yet):

- [primegym](https://github.com/mclebtec/primegym) — trainer guide app
- [galactus-bi](https://github.com/mclebtec/galactus-bi) — virtual analyst / generative insights tool

---

## Contact

[brian.blaze@mclebtec.com](mailto:brian.blaze@mclebtec.com)
