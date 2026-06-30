# Supply Chain Security

## Objective

Secure container delivery for the Paved Road Platform by implementing trusted image repositories, vulnerability scanning, SBOM generation, and cryptographic signing.

---

## Architecture

```text
Developer
    ↓
GitHub Actions
    ↓
OIDC Authentication
    ↓
Cloud Build
    ↓
Artifact Registry
    ↓
Artifact Analysis
    ↓
SBOM Generation (Syft)
    ↓
Cosign Keyless Signing
    ↓
Signature Verification
    ↓
Cloud Run Deployment
```

---

## Components

### Trusted Artifact Repository

Repository:

```text
paved-road-containers
```

Location:

```text
us-central1
```

Purpose:

- Central trusted image repository
- Enterprise artifact management
- Image provenance and lifecycle management

---

### Vulnerability Scanning

Implemented using:

```text
Google Artifact Analysis
```

Capabilities:

- CVE detection
- Package vulnerability analysis
- Continuous scanning of container images

---

### Software Bill of Materials (SBOM)

Implemented using:

```text
Syft
```

Format:

```text
SPDX JSON
```

Example:

```bash
syft <image> -o spdx-json > sbom/image-sbom.json
```

Capabilities:

- Dependency inventory
- Software provenance
- Compliance reporting
- Vulnerability correlation

---

### Image Signing

Implemented using:

```text
Cosign
```

Capabilities:

- Local key-based signing
- GitHub OIDC keyless signing
- Cryptographic integrity verification

---

### CI/CD Integration

Workflow:

```text
.github/workflows/supply-chain-security.yml
```

Pipeline stages:

1. Authenticate using GitHub OIDC
2. Build image using Cloud Build
3. Push image to Artifact Registry
4. Generate SBOM
5. Upload SBOM artifact
6. Sign image using Cosign keyless signing
7. Verify image signature

---

## Enterprise Benefits

- Trusted software provenance
- Cryptographic integrity
- Zero Trust CI/CD
- Dependency visibility
- Automated vulnerability detection
- Supply chain compliance
- Secure software delivery

---

## Future Enhancements

Potential future improvements:

- Binary Authorization
- Admission control with Gatekeeper
- Signed-image deployment enforcement
- SLSA Level 3+ compliance

---

## Talking Points

> Implemented enterprise-grade software supply chain security for the Paved Road Platform using Artifact Registry, Artifact Analysis, Syft, Cosign, and GitHub OIDC-based keyless signing to establish trusted software provenance and integrity throughout the CI/CD pipeline.