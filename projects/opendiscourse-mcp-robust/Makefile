.PHONY: fmt lint test up down logs

fmt:
	black .
	ruff check --fix .

lint:
	ruff check .
	mypy servers/

test:
	pytest

up:
	docker compose up -d --build

down:
	docker compose down -v

logs:
	docker compose logs -f mcp_govdocs mcp_tokenbroker
