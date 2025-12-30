# Octopus Agile Dashboard - Development Commands
# Usage: make [command]
#
# Run `make help` to see all available commands

.PHONY: help install install-hooks lint lint-fix format format-check type-check test clean

# Default target
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RESET := \033[0m

#==============================================================================
# Help
#==============================================================================
help: ## Show this help message
	@echo ""
	@echo "$(CYAN)Octopus Agile Dashboard - Development Commands$(RESET)"
	@echo ""
	@echo "$(GREEN)Usage:$(RESET) make [command]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""

#==============================================================================
# Setup
#==============================================================================
install: ## Install all dependencies (backend and frontend)
	@echo "$(CYAN)Installing backend dependencies...$(RESET)"
	cd backend && pip install -r requirements.txt -r requirements-dev.txt
	@echo "$(CYAN)Installing frontend dependencies...$(RESET)"
	cd frontend && npm install
	@echo "$(GREEN)All dependencies installed!$(RESET)"

install-hooks: ## Install pre-commit hooks
	@echo "$(CYAN)Installing pre-commit hooks...$(RESET)"
	pre-commit install
	@echo "$(GREEN)Pre-commit hooks installed!$(RESET)"

#==============================================================================
# Linting
#==============================================================================
lint: ## Run all linters (backend and frontend)
	@echo "$(CYAN)Running Python linters...$(RESET)"
	cd backend && ruff check app/
	@echo "$(CYAN)Running TypeScript linters...$(RESET)"
	cd frontend && npm run lint
	@echo "$(GREEN)Linting complete!$(RESET)"

lint-fix: ## Run all linters and fix auto-fixable issues
	@echo "$(CYAN)Running Python linters with auto-fix...$(RESET)"
	cd backend && ruff check --fix app/
	@echo "$(CYAN)Running TypeScript linters with auto-fix...$(RESET)"
	cd frontend && npm run lint:fix
	@echo "$(GREEN)Lint fixes applied!$(RESET)"

lint-backend: ## Run Python linters only
	cd backend && ruff check app/

lint-frontend: ## Run TypeScript linters only
	cd frontend && npm run lint

#==============================================================================
# Formatting
#==============================================================================
format: ## Format all code (backend and frontend)
	@echo "$(CYAN)Formatting Python code...$(RESET)"
	cd backend && ruff format app/
	@echo "$(CYAN)Formatting TypeScript code...$(RESET)"
	cd frontend && npm run format
	@echo "$(GREEN)Formatting complete!$(RESET)"

format-check: ## Check formatting without making changes
	@echo "$(CYAN)Checking Python formatting...$(RESET)"
	cd backend && ruff format --check app/
	@echo "$(CYAN)Checking TypeScript formatting...$(RESET)"
	cd frontend && npm run format:check
	@echo "$(GREEN)Format check complete!$(RESET)"

format-backend: ## Format Python code only
	cd backend && ruff format app/

format-frontend: ## Format TypeScript code only
	cd frontend && npm run format

#==============================================================================
# Type Checking
#==============================================================================
type-check: ## Run type checkers (mypy for Python, tsc for TypeScript)
	@echo "$(CYAN)Running mypy...$(RESET)"
	cd backend && mypy app/
	@echo "$(CYAN)Running TypeScript type check...$(RESET)"
	cd frontend && npm run type-check
	@echo "$(GREEN)Type checking complete!$(RESET)"

type-check-backend: ## Run mypy for Python
	cd backend && mypy app/

type-check-frontend: ## Run TypeScript type check
	cd frontend && npm run type-check

#==============================================================================
# Testing
#==============================================================================
test: ## Run all tests
	@echo "$(CYAN)Running backend tests...$(RESET)"
	cd backend && pytest
	@echo "$(GREEN)Tests complete!$(RESET)"

test-cov: ## Run tests with coverage report
	cd backend && pytest --cov=app --cov-report=html --cov-report=term

#==============================================================================
# Pre-commit
#==============================================================================
pre-commit: ## Run pre-commit on all files
	pre-commit run --all-files

pre-commit-update: ## Update pre-commit hooks to latest versions
	pre-commit autoupdate

#==============================================================================
# Full Checks
#==============================================================================
check: ## Run all checks (lint, format-check, type-check)
	@echo "$(CYAN)Running all checks...$(RESET)"
	@$(MAKE) lint
	@$(MAKE) format-check
	@$(MAKE) type-check
	@echo "$(GREEN)All checks passed!$(RESET)"

ci: ## Run CI checks (same as check but non-interactive)
	$(MAKE) lint
	$(MAKE) format-check
	$(MAKE) type-check
	$(MAKE) test

#==============================================================================
# Cleanup
#==============================================================================
clean: ## Clean up generated files and caches
	@echo "$(CYAN)Cleaning up...$(RESET)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "node_modules" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "dist" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "coverage" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "$(GREEN)Cleanup complete!$(RESET)"
