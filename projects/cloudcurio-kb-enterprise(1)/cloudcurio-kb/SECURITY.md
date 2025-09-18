# Security Policy

## Supported Versions
Active development on `main`; releases follow semantic versioning.

## Reporting a Vulnerability
Please open a private advisory or email security@example.com.

## Build & Release Security
- SBOM generated with Syft (SPDX JSON)
- Images signed with Cosign (keyless via GitHub OIDC)
- SLSA provenance attestations emitted on releases
- Trivy vulnerability scans block promotion to `prod` if severity >= HIGH
