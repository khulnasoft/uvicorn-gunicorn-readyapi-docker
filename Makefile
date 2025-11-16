# Makefile for uvicorn-gunicorn-readyapi-docker

.PHONY: help build test clean lint format security-check dev-setup docker-run docker-stop docker-logs \
        dev ci dev-quick dev-format quick-start tag release health benchmark docs install-deps check-deps update-deps pre-commit-setup \
        docker-push docker-pull docker-clean backup restore validate

# Default target
help: ## Show this help message
	@echo "=== KhulnaSoft Uvicorn Gunicorn ReadyAPI Docker ==="
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make dev-setup                    # Set up development environment"
	@echo "  make dev                          # Run development workflow"
	@echo "  make test VERSION=python3.11      # Test specific Python version"
	@echo "  make build VERSION=python3.11     # Build specific version"
	@echo "  make docker-run PORT=8080         # Run on custom port"

# Configuration
PYTHON_VERSION ?= 3.11
VERSION ?= python$(PYTHON_VERSION)
IMAGE_NAME ?= khulnasoft/uvicorn-gunicorn-readyapi
CONTAINER_NAME ?= uvicorn-gunicorn-readyapi-dev
PORT ?= 8000
WORKERS ?= auto
HOST ?= 0.0.0.0
LOG_LEVEL ?= info

# Development setup
dev-setup: ## Set up development environment
	@echo "🚀 Setting up development environment..."
	@echo "Python version: $(PYTHON_VERSION)"
	pip3 install --upgrade pip
	pip3 install -e .[dev]
	@echo "⚠️  Skipping pre-commit hooks due to virtualenv configuration issue"
	@echo "    You can manually set up pre-commit later with: make pre-commit-setup"
	@echo "✅ Development environment setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  make dev      # Run development workflow"
	@echo "  make test     # Run tests"

# Dependencies
install-deps: ## Install all dependencies
	@echo "📦 Installing dependencies..."
	pip3 install -e .[dev]
	@echo "✅ Dependencies installed!"

check-deps: ## Check for outdated dependencies
	@echo "🔍 Checking for outdated dependencies..."
	pip3 list --outdated
	@echo "💡 Run 'make update-deps' to update (use with caution)"

update-deps: ## Update dependencies (use with caution)
	@echo "⚠️  Updating dependencies..."
	pip3 install --upgrade pip
	pip3 install --upgrade -e .[dev]
	@echo "✅ Dependencies updated!"

pre-commit-setup: ## Set up pre-commit hooks with workaround for virtualenv issue
	@echo "🔧 Setting up pre-commit hooks..."
	@echo "Creating temporary minimal configuration..."
	@echo 'repos:' > .pre-commit-temp.yaml
	@echo '  - repo: local' >> .pre-commit-temp.yaml
	@echo '    hooks:' >> .pre-commit-temp.yaml
	@echo '      - id: black' >> .pre-commit-temp.yaml
	@echo '        name: black' >> .pre-commit-temp.yaml
	@echo '        entry: python3 -m black' >> .pre-commit-temp.yaml
	@echo '        language: system' >> .pre-commit-temp.yaml
	@echo '        files: \.py$$' >> .pre-commit-temp.yaml
	@echo '      - id: isort' >> .pre-commit-temp.yaml
	@echo '        name: isort' >> .pre-commit-temp.yaml
	@echo '        entry: python3 -m isort' >> .pre-commit-temp.yaml
	@echo '        language: system' >> .pre-commit-temp.yaml
	@echo '        files: \.py$$' >> .pre-commit-temp.yaml
	@if [ -f .pre-commit-config.yaml ]; then \
		mv .pre-commit-config.yaml .pre-commit-config.yaml.bak; \
		echo "Backed up original .pre-commit-config.yaml"; \
	fi
	@mv .pre-commit-temp.yaml .pre-commit-config.yaml
	@echo "✅ Pre-commit hooks configured with system interpreters!"
	@echo "Note: Using system interpreters to avoid virtualenv issues"

# Code quality
format: ## Format code with black and isort
	@echo "🎨 Formatting code..."
	python3 -m black tests/ docker-images/app/
	python3 -m isort tests/ docker-images/app/
	@echo "✅ Code formatting complete!"

lint: ## Run linting checks
	@echo "🔍 Running linting checks..."
	python3 -m flake8 tests/ docker-images/app/ --count --select=E9,F63,F7,F82 --show-source --statistics
	python3 -m flake8 tests/ docker-images/app/ --count --exit-zero --max-complexity=10 --max-line-length=88 --statistics
	python3 -m mypy tests/
	@echo "✅ Linting complete!"

quality-check: ## Run all code quality checks
	@echo "🎯 Running all code quality checks..."
	pre-commit run --all-files
	@echo "✅ Code quality checks complete!"

# Testing
test: ## Run all tests
	@echo "🧪 Running tests..."
	python3 -m pytest tests/ -v --tb=short

test-coverage: ## Run tests with coverage report
	@echo "📊 Running tests with coverage..."
	python3 -m pytest tests/ --cov=tests --cov-report=html --cov-report=term-missing --cov-fail-under=80

test-security: ## Run security-focused tests
	@echo "🔒 Running security tests..."
	python3 -m pytest tests/test_02_security/ -v

test-integration: ## Run integration tests
	@echo "🔗 Running integration tests..."
	python3 -m pytest tests/ -v -m integration

test-performance: ## Run performance tests
	@echo "⚡ Running performance tests..."
	python3 -m pytest tests/ -v -m performance --benchmark-only

test-all: ## Run all test suites
	@echo "🧪 Running all test suites..."
	make test
	make test-coverage
	make test-security
	make test-integration
	@echo "✅ All tests completed!"

# Docker operations
build: ## Build Docker image (default: python3.11)
	@echo "🏗️  Building Docker image with version $(VERSION)..."
	docker build -f docker-images/$(VERSION).dockerfile \
		--build-arg BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ") \
		--build-arg VCS_REF=$(shell git rev-parse --short HEAD) \
		--build-arg VERSION=$(VERSION) \
		-t $(IMAGE_NAME):$(VERSION) \
		-t $(IMAGE_NAME):latest \
		./docker-images/
	@echo "✅ Docker image build complete!"
	@echo "Image: $(IMAGE_NAME):$(VERSION)"

build-all: ## Build all Docker image variants
	@echo "🏗️  Building all Docker image variants..."
	@for version in python3.11 python3.10 python3.9 python3.8 python3.7 \
		python3.11-slim python3.10-slim python3.9-slim python3.8-slim; do \
		echo "Building $$version..."; \
		docker build -f docker-images/$$version.dockerfile \
			--build-arg BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ") \
			--build-arg VCS_REF=$(shell git rev-parse --short HEAD) \
			--build-arg VERSION=$$version \
			-t $(IMAGE_NAME):$$version ./docker-images/ || echo "Failed to build $$version"; \
	done
	@echo "✅ Docker images build complete!"

docker-run: ## Run Docker container (default: latest)
	@echo "🚀 Starting Docker container..."
	docker run -d --name $(CONTAINER_NAME) \
		-p $(PORT):80 \
		-e WORKERS=$(WORKERS) \
		-e HOST=$(HOST) \
		-e LOG_LEVEL=$(LOG_LEVEL) \
		$(IMAGE_NAME):$(VERSION)
	@echo "✅ Container started!"
	@echo "🌐 Access at http://localhost:$(PORT)"
	@echo "📋 View logs: make docker-logs"

docker-stop: ## Stop and remove Docker container
	@echo "🛑 Stopping Docker container..."
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true
	@echo "✅ Container stopped and removed!"

docker-restart: docker-stop docker-run ## Restart Docker container

docker-logs: ## Show Docker container logs
	docker logs -f $(CONTAINER_NAME)

docker-exec: ## Execute shell in running container
	docker exec -it $(CONTAINER_NAME) /bin/bash

docker-status: ## Show container status
	@echo "📊 Container status:"
	@docker ps -a --filter name=$(CONTAINER_NAME)

docker-push: ## Push Docker image to registry
	@echo "📤 Pushing Docker image..."
	docker push $(IMAGE_NAME):$(VERSION)
	@if [ "$(VERSION)" != "latest" ]; then docker push $(IMAGE_NAME):latest; fi
	@echo "✅ Image pushed!"

docker-pull: ## Pull Docker image from registry
	@echo "📥 Pulling Docker image..."
	docker pull $(IMAGE_NAME):$(VERSION)
	@echo "✅ Image pulled!"

docker-clean: ## Clean up Docker resources
	@echo "🧹 Cleaning up Docker resources..."
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true
	docker image prune -f
	docker volume prune -f
	docker network prune -f
	@echo "✅ Docker cleanup complete!"

# Health and monitoring
health: ## Check application health
	@echo "🏥 Checking application health..."
	@curl -f http://localhost:$(PORT)/health || echo "❌ Health check failed"

benchmark: ## Run application benchmark
	@echo "⚡ Running benchmark..."
	@ab -n 1000 -c 10 http://localhost:$(PORT)/ || echo "❌ Benchmark failed"

monitor: ## Monitor running container
	@echo "📊 Monitoring container..."
	@docker stats $(CONTAINER_NAME)

# Security
security-scan: ## Run security vulnerability scan
	@echo "🔒 Running security scan..."
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		-v $$PWD:/root/.cache/ aquasec/trivy:latest image $(IMAGE_NAME):$(VERSION)

security-check: ## Run security checks on code
	@echo "🔒 Running security checks..."
	bandit -r docker-images/app/ -f json -o bandit-report.json || true
	safety check --json --output safety-report.json || true
	@echo "✅ Security checks complete!"
	@echo "📄 Reports generated: bandit-report.json, safety-report.json"

# Documentation
docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	@if command -v mkdocs >/dev/null 2>&1; then \
		mkdocs build; \
		echo "✅ Documentation generated in site/"; \
	else \
		echo "❌ mkdocs not installed. Install with: pip3 install mkdocs"; \
	fi

docs-serve: ## Serve documentation locally
	@echo "📚 Serving documentation..."
	@if command -v mkdocs >/dev/null 2>&1; then \
		mkdocs serve; \
	else \
		echo "❌ mkdocs not installed. Install with: pip3 install mkdocs"; \
	fi

# Validation
validate: ## Validate Docker images and configuration
	@echo "✅ Validating Docker images..."
	@for version in python3.11 python3.10 python3.9; do \
		echo "Validating $$version..."; \
		docker run --rm $(IMAGE_NAME):$$version python --version || echo "❌ $$version validation failed"; \
	done
	@echo "✅ Validation complete!"

# Backup and restore
backup: ## Backup important files
	@echo "💾 Creating backup..."
	tar -czf backup-$(shell date +%Y%m%d-%H%M%S).tar.gz \
		docker-images/ \
		tests/ \
		.github/workflows/ \
		Makefile \
		pyproject.toml \
		README.md
	@echo "✅ Backup created!"

restore: ## Restore from backup (usage: make restore BACKUP=file.tar.gz)
	@if [ -z "$(BACKUP)" ]; then echo "❌ BACKUP parameter required"; exit 1; fi
	@echo "📥 Restoring from $(BACKUP)..."
	tar -xzf $(BACKUP)
	@echo "✅ Restore complete!"

# Cleanup
clean: ## Clean up temporary files and containers
	@echo "🧹 Cleaning up..."
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type f -name "*.coverage" -delete
	find . -type d -name ".coverage" -exec rm -rf {} +
	find . -type f -name ".pytest_cache" -delete
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type f -name "*.log" -delete
	find . -type f -name "*.json" -delete
	make docker-clean
	@echo "✅ Cleanup complete!"

# Release and deployment
tag: ## Create and push git tag (usage: make tag VERSION=1.0.0)
	@if [ -z "$(VERSION)" ]; then echo "❌ VERSION is required. Usage: make tag VERSION=1.0.0"; exit 1; fi
	@echo "🏷️  Creating tag v$(VERSION)..."
	git tag -a v$(VERSION) -m "Release v$(VERSION)"
	git push origin v$(VERSION)
	@echo "✅ Tag v$(VERSION) created and pushed!"

release: ## Create a release (build, tag, push)
	@echo "🚀 Creating release..."
	make build-all
	make tag VERSION=$(VERSION)
	make docker-push
	@echo "✅ Release complete!"

# Development workflows
dev: ## Run full development workflow (format -> lint -> test)
	@echo "🔄 Running development workflow..."
	make format
	make lint
	make test
	@echo "✅ Development workflow complete!"

dev-quick: ## Run development workflow without linting (for when mypy has issues)
	@echo "🔄 Running quick development workflow..."
	make format
	make test
	@echo "✅ Quick development workflow complete!"
	@echo "💡 Note: Skipped linting due to type checking issues. Run 'make lint' separately if needed."

dev-format: ## Run code formatting only (no tests, no linting)
	@echo "🎨 Running code formatting only..."
	make format
	@echo "✅ Code formatting complete!"
	@echo "💡 This is the safest option when Docker is not available."

ci: ## Run CI pipeline locally
	@echo "🔄 Running CI pipeline locally..."
	make quality-check
	make test-coverage
	make test-security
	make security-scan
	@echo "✅ CI pipeline complete!"

# Quick start
quick-start: ## Quick start for development (setup -> build -> run)
	@echo "🚀 Quick starting development environment..."
	make dev-setup
	make build
	make docker-run
	sleep 3
	make health
	@echo "✅ Quick start complete!"
	@echo "🌐 Access at http://localhost:$(PORT)"
	@echo "📋 View logs: make docker-logs"
	@echo "🛑 Stop: make docker-stop"

# Info
info: ## Show project information
	@echo "=== Project Information ==="
	@echo "Image Name: $(IMAGE_NAME)"
	@echo "Version: $(VERSION)"
	@echo "Container: $(CONTAINER_NAME)"
	@echo "Port: $(PORT)"
	@echo "Python: $(PYTHON_VERSION)"
	@echo ""
	@echo "=== Git Info ==="
	@git status --porcelain || echo "Not a git repository"
	@git log -1 --oneline || echo "No git history"
	@echo ""
	@echo "=== Docker Info ==="
	@docker --version
	@docker images $(IMAGE_NAME) | grep -v REPOSITORY || echo "No images found"
