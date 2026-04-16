.PHONY: help install start stop restart logs status update clean build test migrate shell

# Default target
help:
	@echo "Email Delivery Platform - Makefile Commands"
	@echo "=========================================="
	@echo ""
	@echo "Setup Commands:"
	@echo "  make install    - Install the platform"
	@echo "  make build      - Build all Docker images"
	@echo ""
	@echo "Runtime Commands:"
	@echo "  make start      - Start all services"
	@echo "  make stop       - Stop all services"
	@echo "  make restart    - Restart all services"
	@echo "  make logs       - View logs"
	@echo "  make status     - Check service status"
	@echo ""
	@echo "Development Commands:"
	@echo "  make migrate    - Run database migrations"
	@echo "  make test       - Run tests"
	@echo "  make shell      - Open backend shell"
	@echo "  make clean      - Clean up containers and volumes"
	@echo ""
	@echo "Update Commands:"
	@echo "  make update     - Update to latest version"
	@echo "  make pull       - Pull latest images"

# Installation
install:
	@echo "Installing Email Delivery Platform..."
	@sudo ./install.sh

# Build all images
build:
	@echo "Building Docker images..."
	@docker-compose build

# Start services
start:
	@echo "Starting services..."
	@docker-compose up -d
	@echo "Services started!"
	@echo "Dashboard: http://localhost:3000"
	@echo "API: http://localhost:8000"

# Stop services
stop:
	@echo "Stopping services..."
	@docker-compose down
	@echo "Services stopped!"

# Restart services
restart:
	@echo "Restarting services..."
	@docker-compose restart
	@echo "Services restarted!"

# View logs
logs:
	@docker-compose logs -f

# Check status
status:
	@docker-compose ps

# Update
update:
	@echo "Updating to latest version..."
	@docker-compose pull
	@docker-compose up -d --build
	@echo "Update complete!"

# Pull latest images
pull:
	@docker-compose pull

# Database migrations
migrate:
	@docker-compose exec backend alembic upgrade head

# Create migration
create-migration:
	@docker-compose exec backend alembic revision --autogenerate -m "$(message)"

# Run tests
test:
	@docker-compose exec backend pytest

# Open backend shell
shell:
	@docker-compose exec backend bash

# Clean up
clean:
	@echo "Cleaning up..."
	@docker-compose down -v
	@docker system prune -f
	@echo "Cleanup complete!"

# Deep clean (removes all data)
clean-all:
	@echo "WARNING: This will remove all data!"
	@read -p "Are you sure? (y/N) " confirm && [ $$confirm = y ]
	@docker-compose down -v
	@rm -rf database/postgres_data/*
	@rm -rf database/redis_data/*
	@rm -rf database/postfix_data/*
	@docker system prune -f
	@echo "All data removed!"

# Backup database
backup:
	@mkdir -p backups
	@docker-compose exec postgres pg_dump -U emailuser emailplatform > backups/backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "Backup created!"

# Restore database
restore:
	@if [ -z "$(file)" ]; then \
		echo "Usage: make restore file=backups/backup_YYYYMMDD_HHMMSS.sql"; \
		exit 1; \
	fi
	@docker-compose exec -T postgres psql -U emailuser emailplatform < $(file)
	@echo "Restore complete!"

# Development mode (with hot reload)
dev:
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Production mode
prod:
	@docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Scale workers
scale-workers:
	@docker-compose up -d --scale email-worker=4 --scale campaign-worker=2

# View backend logs
logs-backend:
	@docker-compose logs -f backend

# View frontend logs
logs-frontend:
	@docker-compose logs -f frontend

# View worker logs
logs-workers:
	@docker-compose logs -f email-worker campaign-worker bounce-worker

# Database console
db-console:
	@docker-compose exec postgres psql -U emailuser -d emailplatform

# Redis console
redis-console:
	@docker-compose exec redis redis-cli
