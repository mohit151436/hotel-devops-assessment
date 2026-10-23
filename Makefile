# Convenience wrappers. Every target just calls the scripts in scripts/.
.PHONY: help up down reset backup restore verify explain psql tf-dev tf-prod tf-all

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-10s %s\n", $$1, $$2}'

up: ## Start PostgreSQL and wait until migrations + seed are done
	docker compose up -d --wait

down: ## Stop PostgreSQL (keeps data)
	docker compose down

reset: ## Delete all local data and start again from a fresh seed
	docker compose down -v
	docker compose up -d --wait

backup: ## Create a timestamped backup in backups/
	./scripts/backup.sh

restore: ## Restore the latest backup into a fresh database (hotel_restore)
	./scripts/restore.sh

verify: ## Compare the restored database with the source
	./scripts/verify-restore.sh

explain: ## Show the reporting query plan without and with the index
	./scripts/explain-query.sh

psql: ## Open psql in the database container
	docker compose exec db psql -U $${DB_USER:-hotel_user} -d $${DB_NAME:-hotel}

tf-dev: ## Terraform fmt/init/validate/plan for dev (no AWS needed)
	./scripts/tf-check.sh dev

tf-prod: ## Terraform fmt/init/validate/plan for prod (no AWS needed)
	./scripts/tf-check.sh prod

tf-all: tf-dev tf-prod ## Terraform checks for both environments
