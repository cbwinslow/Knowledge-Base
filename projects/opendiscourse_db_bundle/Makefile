
SHELL := /usr/bin/env bash
ENV ?= .env

include $(ENV)
export

.PHONY: up down logs init qdrant refresh backup restore

up:
	docker compose --env-file $(ENV) up -d --build

init: up
	docker compose --env-file $(ENV) up db_init qdrant_init --no-deps --build

logs:
	docker compose --env-file $(ENV) logs -f

down:
	docker compose --env-file $(ENV) down

refresh:
	docker compose exec -T postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -v ON_ERROR_STOP=1 -f /docker-entrypoint-initdb.d/refresh_matviews.sql

backup:
	bash scripts/backup.sh

restore:
	bash scripts/restore.sh
