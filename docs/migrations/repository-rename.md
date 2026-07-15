# Repository Rename

The GitHub repository and platform identifier were renamed from `paved-road-engine` to `paved-road-platform`.

## Updated Components

- **Git Remote URL:** Points to the new repository home.
- **GitHub Workload Identity Federation (WIF) Bindings:** Adjusted service account IAM member bindings to authorize the new repository name.
- **Terraform Labels:** Standardized platform tracking tags.
- **Application Environment Variables:** Aligned runtimes with the `paved-road-platform` identity.
- **Backstage Annotations:** Updated project-slug integrations and catalog entity definitions.
- **GitHub Actions Workflows:** Standardized workflow steps and keyless signing identities.
- **Documentation:** Consolidated instruction paths and references in markdown files.
- **Container Image Naming:** Aligned Artifact Registry paths to use a single application image name.

## Preserved Components

The following deployed resource names were explicitly retained to maintain service continuity and avoid destructive resource replacement:

- **Existing Cloud Run Service Names** (e.g., `backstage-acceptance-test`)
- **Workload Identity Pool ID**
- **Workload Identity Provider ID**
- **Existing Terraform State Buckets**
