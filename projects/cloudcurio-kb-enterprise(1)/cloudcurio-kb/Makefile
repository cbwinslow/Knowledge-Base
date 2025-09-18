

sbom:
	# Generate SBOMs for images already built locally
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $$(pwd):/out anchore/syft:latest registry:ghcr.io/OWNER/cloudcurio-bff:edge -o spdx-json=/out/sbom-bff.spdx.json || true
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $$(pwd):/out anchore/syft:latest registry:ghcr.io/OWNER/cloudcurio-admin:edge -o spdx-json=/out/sbom-admin.spdx.json || true

scan:
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image ghcr.io/OWNER/cloudcurio-bff:edge || true
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image ghcr.io/OWNER/cloudcurio-admin:edge || true

