# Paved Road Platform

## Overview

The Paved Road Platform is an Enterprise Internal Developer Platform (IDP) built on Google Cloud.

The platform enables developers to provision secure, governed, observable, and cost-aware infrastructure through standardized self-service workflows.

---

## Platform Capabilities

- Self-service infrastructure provisioning
- GitHub Actions CI/CD automation
- Policy as Code (OPA)
- Infrastructure validation
- Cloud Run deployment automation
- Observability and SLO management
- FinOps and cost governance
- Software supply chain security
- Backstage self-service portal

---

## Architecture

```text
Developer
    ↓
Backstage Portal
    ↓
Scaffolder Template
    ↓
GitHub Pull Request
    ↓
Policy Validation
    ↓
Terraform Validation
    ↓
Terraform Deployment
    ↓
Google Cloud Platform
```

---

## Supported Workloads

### Cloud Run

Recommended for:

- APIs
- Microservices
- Event-driven workloads
- Stateless applications

---

## Getting Started

1. Open Backstage.
2. Select **Create**.
3. Choose the **Cloud Run Template**.
4. Enter deployment parameters.
5. Submit the template.
6. Review the generated Pull Request.
7. Merge after validation succeeds.
8. Monitor deployment status.

---

## Platform Standards

Every workload deployed through the platform must:

- Use approved templates
- Pass policy validation
- Include mandatory labels
- Meet security requirements
- Use trusted container images

---

## Platform Ownership

| Attribute | Value |
|-----------|-------|
| Owner | platform-team |
| Lifecycle | production |
| Platform Type | Internal Developer Platform |
| Cloud Provider | Google Cloud Platform |

---

## Additional Documentation

- Golden Paths
- Operational Runbooks
- Troubleshooting Guides
- Security Standards
- FinOps Standards