# Makefile for uvicorn-gunicorn-readyapi-docker

.PHONY: help build test clean lint format security-check dev-setup docker-run docker-stop docker-logs

# Default target
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Development setup
dev-setup: ## Set up development environment
	@echo "Setting up development environment..."
	pip install -e .[dev]
	pre-commit install
	@echo "Development environment setup complete!"

# Code quality
lint: ## Run linting checks
	@echo "Running linting checks..."
	flake8 tests/ docker-images/app/
	mypy tests/
	@echo "Linting complete!"

format: ## Format code with black and isort
	@echo "Formatting code..."
	black tests/ docker-images/app/
	isort tests/ docker-images/app/
	@echo "Code formatting complete!"

quality-check: ## Run all code quality checks
	@echo "Running all code quality checks..."
	pre-commit run --all-files
	@echo "Code quality checks complete!"

# Testing
test: ## Run all tests
	@echo "Running tests..."
	pytest tests/ -v

test-coverage: ## Run tests with coverage report
	@echo "Running tests with coverage..."
	pytest tests/ --cov=tests --cov-report=html --cov-report=term-missing

test-security: ## Run security-focused tests
	@echo "Running security tests..."
	pytest tests/test_02_security/ -v

test-integration: ## Run integration tests
	@echo "Running integration tests..."
	pytest tests/ -v -m integration

# Docker operations
VERSION ?= python3.11
IMAGE_NAME ?= khulnasoft/uvicorn-gunicorn-readyapi
CONTAINER_NAME ?= uvicorn-gunicorn-readyapi-dev

build: ## Build Docker image (default: python3.11)
	@echo "Building Docker image with version $(VERSION)..."
	docker build -f docker-images/$(VERSION).dockerfile -t $(IMAGE_NAME):$(VERSION) ./docker-images/
	docker tag $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest
	@echo "Docker image build complete!"

build-all: ## Build all Docker image variants
	@echo "Building all Docker image variants..."
	for version in python3.11 python3.10 python3.9 python3.11-slim python3.10-slim python3.9-slim; do \
		echo "Building $$version..."; \
		docker build -f docker-images/$$version.dockerfile -t $(IMAGE_NAME):$$version ./docker-images/; \
	done
	@echo "All Docker images built successfully!"

docker-run: ## Run Docker container (default: latest)
	@echo "Starting Docker container..."
	docker run -d --name $(CONTAINER_NAME) -p 8000:80 $(IMAGE_NAME):$(VERSION)
	@echo "Container started! Access at http://localhost:8000"

docker-stop: ## Stop and remove Docker container
	@echo "Stopping Docker container..."
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true
	@echo "Container stopped and removed!"

docker-logs: ## Show Docker container logs
	docker logs -f $(CONTAINER_NAME)

docker-exec: ## Execute shell in running container
	docker exec -it $(CONTAINER_NAME) /bin/bash

# Security
security-scan: ## Run security vulnerability scan
	@echo "Running security scan..."
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		-v $$PWD:/root/.cache/ aquasec/trivy:latest image $(IMAGE_NAME):$(VERSION)

security-check: ## Run security checks on code
	@echo "Running security checks..."
	bandit -r docker-images/app/
	safety check
	@echo "Security checks complete!"

# Cleanup
clean: ## Clean up temporary files and containers
	@echo "Cleaning up..."
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true
	docker system prune -f
	@echo "Cleanup complete!"

# Release and deployment
tag: ## Create and push git tag (usage: make tag VERSION=1.0.0)
	@if [ -z "$(VERSION)" ]; then echo "Error: VERSION is required. Usage: make tag VERSION=1.0.0"; exit 1; fi
	@echo "Creating tag v$(VERSION)..."
	git tag -a v$(VERSION) -m "Release v$(VERSION)"
	git push origin v$(VERSION)
	@echo "Tag v$(VERSION) created and pushed!"

# Development workflow
dev: ## Run full development workflow (format -> lint -> test)
	@echo "Running development workflow..."
	make format
	make lint
	make test
	@echo "Development workflow complete!"

ci: ## Run CI pipeline locally
	@echo "Running CI pipeline locally..."
	make quality-check
	make test-coverage
	make test-security
	make security-scan
	@echo "CI pipeline complete!"

# Quick start
quick-start: ## Quick start for development (setup -> build -> run)
	@echo "Quick starting development environment..."
	make dev-setup
	make build
	make docker-run
	@echo "Quick start complete! Access at http://localhost:8000"
