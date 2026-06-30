The Paved Road Platform generates SBOMs for container images using Syft.

SBOM generation provides:

- dependency inventory
- software provenance
- vulnerability correlation
- compliance reporting
- software supply chain visibility

Example:

syft <image> -o spdx-json > sbom/image-sbom.json