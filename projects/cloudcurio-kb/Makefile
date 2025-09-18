    .PHONY: up down logs init terraform-apply bootstrap
    up:
		docker compose up -d
    down:
		docker compose down
    logs:
		docker compose logs -f --tail=200
    init:
		bash scripts/run_initializers.sh
    bootstrap:
		python3 scripts/terminus_bootstrap.py
    terraform-apply:
		cd terraform && terraform init && terraform apply -auto-approve
