# CloudCurio KB — final build (observability, security, exports)

## Admin Console
- `apps/admin` (Next.js)

## Managed Redis
- Terraform modules under `terraform/redis`

## Exports
- `scripts/export` for NDJSON/CSV/Parquet via TerminusDB client

## CI/CD
- GitHub Actions: `.github/workflows/ci.yml` and `release.yml` build & publish images to GHCR.
