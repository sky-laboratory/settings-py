# =============================================================================
# CollabOps settings-py: FastAPI Stack - python.mk
# =============================================================================
# 이 파일은 중앙 템플릿 레포(settings-py)에서 관리됩니다.
# 서비스 레포의 Makefile에서 include하여 사용합니다.
#
# 사용법 (서비스 레포 Makefile):
#   PYTHON_MK_URL := https://raw.githubusercontent.com/.../python.mk
#   include python.mk (또는 curl로 다운로드 후 include)
# =============================================================================

.PHONY: check-venv sync format lint test test-unit test-integration test-cov \
        local local-it build-it clean clean-all run migrate help

# =============================================================================
# Overridable Variables (서비스 레포에서 오버라이드 가능)
# =============================================================================

# Docker Compose 설정
DOCKER_COMPOSE_DIR    ?= ./docker
LOCAL_COMPOSE_FILE    ?= $(DOCKER_COMPOSE_DIR)/docker-compose.local.yml
LOCAL_IT_COMPOSE_FILE ?= $(DOCKER_COMPOSE_DIR)/docker-compose.local-it.yml
BUILD_IT_COMPOSE_FILE ?= $(DOCKER_COMPOSE_DIR)/docker-compose.build-it.yml
QA_COMPOSE_FILE       ?= $(DOCKER_COMPOSE_DIR)/docker-compose.qa.yml

# uv 경로 (시스템 설치 또는 로컬 설치)
UV ?= uv

# 테스트 디렉토리
TEST_DIR          ?= tests
TEST_UNIT_DIR     ?= $(TEST_DIR)/unit
TEST_INT_DIR      ?= $(TEST_DIR)/integration
TEST_E2E_DIR      ?= $(TEST_DIR)/e2e

# FastAPI 설정
APP_MAIN          ?= app.main:app
APP_HOST          ?= 0.0.0.0
APP_PORT          ?= 8000
APP_RELOAD        ?= --reload
APP_WORKERS       ?= 4

# Python 설정
PYTHON_VERSION    ?= 3.12
SRC_DIR           ?= src
VENV_DIR          ?= .venv

# Coverage 설정
COV_MIN           ?= 80
COV_REPORT        ?= html

# =============================================================================
# Internal Variables (변경하지 마세요)
# =============================================================================

DOCKER_COMPOSE := docker compose
PYTEST         := $(UV) run pytest
RUFF           := $(UV) run ruff
MYPY           := $(UV) run mypy
UVICORN        := $(UV) run uvicorn

# 색상 코드
COLOR_RESET  := \033[0m
COLOR_GREEN  := \033[32m
COLOR_YELLOW := \033[33m
COLOR_BLUE   := \033[34m
COLOR_RED    := \033[31m

# =============================================================================
# Help
# =============================================================================

help: ## Show this help message
	@echo "$(COLOR_BLUE)CollabOps FastAPI Stack - Available Commands$(COLOR_RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_GREEN)%-20s$(COLOR_RESET) %s\n", $$1, $$2}'

# =============================================================================
# Environment Setup
# =============================================================================

check-venv: ## Check if virtual environment exists
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "$(COLOR_YELLOW)[WARN] Virtual environment not found. Creating...$(COLOR_RESET)"; \
		$(UV) venv --python $(PYTHON_VERSION); \
	fi
	@echo "$(COLOR_GREEN)[OK] Virtual environment ready$(COLOR_RESET)"

sync: check-venv ## Sync dependencies with uv (local + qa groups)
	@echo "$(COLOR_BLUE)[INFO] Syncing dependencies...$(COLOR_RESET)"
	$(UV) sync --group local --group qa
	@echo "$(COLOR_GREEN)[OK] Dependencies synced$(COLOR_RESET)"

sync-prod: check-venv ## Sync production dependencies
	@echo "$(COLOR_BLUE)[INFO] Syncing production dependencies...$(COLOR_RESET)"
	$(UV) sync --group prod
	@echo "$(COLOR_GREEN)[OK] Production dependencies synced$(COLOR_RESET)"

sync-stage: check-venv ## Sync staging dependencies
	@echo "$(COLOR_BLUE)[INFO] Syncing staging dependencies...$(COLOR_RESET)"
	$(UV) sync --group stage
	@echo "$(COLOR_GREEN)[OK] Staging dependencies synced$(COLOR_RESET)"

# =============================================================================
# Code Quality
# =============================================================================

format: check-venv ## Format code with ruff
	@echo "$(COLOR_BLUE)[INFO] Formatting code...$(COLOR_RESET)"
	$(RUFF) format $(SRC_DIR) $(TEST_DIR)
	$(RUFF) check --fix $(SRC_DIR) $(TEST_DIR)
	@echo "$(COLOR_GREEN)[OK] Code formatted$(COLOR_RESET)"

lint: check-venv ## Lint code with ruff (no fix)
	@echo "$(COLOR_BLUE)[INFO] Linting code...$(COLOR_RESET)"
	$(RUFF) check $(SRC_DIR) $(TEST_DIR)
	@echo "$(COLOR_GREEN)[OK] Lint passed$(COLOR_RESET)"

typecheck: check-venv ## Type check with mypy
	@echo "$(COLOR_BLUE)[INFO] Type checking...$(COLOR_RESET)"
	$(MYPY) $(SRC_DIR)
	@echo "$(COLOR_GREEN)[OK] Type check passed$(COLOR_RESET)"

check: lint typecheck ## Run all code quality checks

# =============================================================================
# Testing
# =============================================================================

test: check-venv ## Run all tests
	@echo "$(COLOR_BLUE)[INFO] Running all tests...$(COLOR_RESET)"
	$(PYTEST) $(TEST_DIR) -v
	@echo "$(COLOR_GREEN)[OK] All tests passed$(COLOR_RESET)"

test-unit: check-venv ## Run unit tests only
	@echo "$(COLOR_BLUE)[INFO] Running unit tests...$(COLOR_RESET)"
	$(PYTEST) $(TEST_UNIT_DIR) -v -m "unit or not integration"
	@echo "$(COLOR_GREEN)[OK] Unit tests passed$(COLOR_RESET)"

test-integration: check-venv ## Run integration tests only
	@echo "$(COLOR_BLUE)[INFO] Running integration tests...$(COLOR_RESET)"
	$(PYTEST) $(TEST_INT_DIR) -v -m "integration"
	@echo "$(COLOR_GREEN)[OK] Integration tests passed$(COLOR_RESET)"

test-e2e: check-venv ## Run e2e tests only
	@echo "$(COLOR_BLUE)[INFO] Running e2e tests...$(COLOR_RESET)"
	$(PYTEST) $(TEST_E2E_DIR) -v -m "e2e"
	@echo "$(COLOR_GREEN)[OK] E2E tests passed$(COLOR_RESET)"

test-cov: check-venv ## Run tests with coverage
	@echo "$(COLOR_BLUE)[INFO] Running tests with coverage...$(COLOR_RESET)"
	$(PYTEST) $(TEST_DIR) \
		--cov=$(SRC_DIR) \
		--cov-report=$(COV_REPORT) \
		--cov-report=term-missing \
		--cov-fail-under=$(COV_MIN) \
		-v
	@echo "$(COLOR_GREEN)[OK] Coverage report generated$(COLOR_RESET)"

# =============================================================================
# Local Development
# =============================================================================

run: check-venv ## Run FastAPI development server
	@echo "$(COLOR_BLUE)[INFO] Starting FastAPI server...$(COLOR_RESET)"
	$(UVICORN) $(APP_MAIN) --host $(APP_HOST) --port $(APP_PORT) $(APP_RELOAD)

run-prod: check-venv ## Run FastAPI with gunicorn (production mode)
	@echo "$(COLOR_BLUE)[INFO] Starting FastAPI with gunicorn...$(COLOR_RESET)"
	$(UV) run gunicorn $(APP_MAIN) \
		-w $(APP_WORKERS) \
		-k uvicorn.workers.UvicornWorker \
		-b $(APP_HOST):$(APP_PORT)

local: ## Start local development environment (Docker Compose)
	@echo "$(COLOR_BLUE)[INFO] Starting local environment...$(COLOR_RESET)"
	@if [ ! -f "$(LOCAL_COMPOSE_FILE)" ]; then \
		echo "$(COLOR_RED)[ERROR] $(LOCAL_COMPOSE_FILE) not found$(COLOR_RESET)"; \
		exit 1; \
	fi
	$(DOCKER_COMPOSE) -f $(LOCAL_COMPOSE_FILE) up -d
	@echo "$(COLOR_GREEN)[OK] Local environment started$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)[INFO] API available at http://localhost:$(APP_PORT)$(COLOR_RESET)"

local-down: ## Stop local development environment
	@echo "$(COLOR_BLUE)[INFO] Stopping local environment...$(COLOR_RESET)"
	$(DOCKER_COMPOSE) -f $(LOCAL_COMPOSE_FILE) down
	@echo "$(COLOR_GREEN)[OK] Local environment stopped$(COLOR_RESET)"

local-logs: ## View local environment logs
	$(DOCKER_COMPOSE) -f $(LOCAL_COMPOSE_FILE) logs -f

local-restart: local-down local ## Restart local environment

# =============================================================================
# Integration Testing with Docker
# =============================================================================

local-it: ## Start local integration test environment
	@echo "$(COLOR_BLUE)[INFO] Starting local-it environment...$(COLOR_RESET)"
	@if [ ! -f "$(LOCAL_IT_COMPOSE_FILE)" ]; then \
		echo "$(COLOR_RED)[ERROR] $(LOCAL_IT_COMPOSE_FILE) not found$(COLOR_RESET)"; \
		exit 1; \
	fi
	$(DOCKER_COMPOSE) -f $(LOCAL_IT_COMPOSE_FILE) up -d
	@echo "$(COLOR_GREEN)[OK] Local-it environment started$(COLOR_RESET)"

local-it-down: ## Stop local integration test environment
	@echo "$(COLOR_BLUE)[INFO] Stopping local-it environment...$(COLOR_RESET)"
	$(DOCKER_COMPOSE) -f $(LOCAL_IT_COMPOSE_FILE) down -v
	@echo "$(COLOR_GREEN)[OK] Local-it environment stopped$(COLOR_RESET)"

local-it-test: local-it ## Run integration tests against local-it
	@echo "$(COLOR_BLUE)[INFO] Running integration tests...$(COLOR_RESET)"
	@sleep 5  # Wait for services to be ready
	$(PYTEST) $(TEST_INT_DIR) -v -m "integration"
	@$(MAKE) local-it-down
	@echo "$(COLOR_GREEN)[OK] Integration tests completed$(COLOR_RESET)"

build-it: ## Build and run integration test environment
	@echo "$(COLOR_BLUE)[INFO] Building integration test environment...$(COLOR_RESET)"
	@if [ ! -f "$(BUILD_IT_COMPOSE_FILE)" ]; then \
		echo "$(COLOR_RED)[ERROR] $(BUILD_IT_COMPOSE_FILE) not found$(COLOR_RESET)"; \
		exit 1; \
	fi
	$(DOCKER_COMPOSE) -f $(BUILD_IT_COMPOSE_FILE) build
	$(DOCKER_COMPOSE) -f $(BUILD_IT_COMPOSE_FILE) up -d
	@echo "$(COLOR_GREEN)[OK] Build-it environment ready$(COLOR_RESET)"

build-it-down: ## Stop build integration test environment
	@echo "$(COLOR_BLUE)[INFO] Stopping build-it environment...$(COLOR_RESET)"
	$(DOCKER_COMPOSE) -f $(BUILD_IT_COMPOSE_FILE) down -v --rmi local
	@echo "$(COLOR_GREEN)[OK] Build-it environment stopped$(COLOR_RESET)"

build-it-test: build-it ## Run tests against build-it environment
	@echo "$(COLOR_BLUE)[INFO] Running build-it tests...$(COLOR_RESET)"
	@sleep 5
	$(PYTEST) $(TEST_INT_DIR) $(TEST_E2E_DIR) -v
	@$(MAKE) build-it-down
	@echo "$(COLOR_GREEN)[OK] Build-it tests completed$(COLOR_RESET)"

# =============================================================================
# QA Environment
# =============================================================================

qa-up: ## Start QA environment
	@echo "$(COLOR_BLUE)[INFO] Starting QA environment...$(COLOR_RESET)"
	@if [ ! -f "$(QA_COMPOSE_FILE)" ]; then \
		echo "$(COLOR_RED)[ERROR] $(QA_COMPOSE_FILE) not found$(COLOR_RESET)"; \
		exit 1; \
	fi
	$(DOCKER_COMPOSE) -f $(QA_COMPOSE_FILE) up -d
	@echo "$(COLOR_GREEN)[OK] QA environment started$(COLOR_RESET)"

qa-down: ## Stop QA environment
	$(DOCKER_COMPOSE) -f $(QA_COMPOSE_FILE) down -v
	@echo "$(COLOR_GREEN)[OK] QA environment stopped$(COLOR_RESET)"

# =============================================================================
# Cleanup
# =============================================================================

clean: ## Clean temporary files and caches
	@echo "$(COLOR_BLUE)[INFO] Cleaning temporary files...$(COLOR_RESET)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type f -name ".coverage" -delete 2>/dev/null || true
	rm -rf htmlcov/ .coverage coverage.xml 2>/dev/null || true
	rm -rf dist/ build/ 2>/dev/null || true
	@echo "$(COLOR_GREEN)[OK] Cleaned$(COLOR_RESET)"

clean-venv: ## Remove virtual environment
	@echo "$(COLOR_BLUE)[INFO] Removing virtual environment...$(COLOR_RESET)"
	rm -rf $(VENV_DIR)
	@echo "$(COLOR_GREEN)[OK] Virtual environment removed$(COLOR_RESET)"

clean-docker: ## Clean Docker resources for this project
	@echo "$(COLOR_BLUE)[INFO] Cleaning Docker resources...$(COLOR_RESET)"
	$(DOCKER_COMPOSE) -f $(LOCAL_COMPOSE_FILE) down -v --rmi local 2>/dev/null || true
	$(DOCKER_COMPOSE) -f $(LOCAL_IT_COMPOSE_FILE) down -v --rmi local 2>/dev/null || true
	$(DOCKER_COMPOSE) -f $(BUILD_IT_COMPOSE_FILE) down -v --rmi local 2>/dev/null || true
	@echo "$(COLOR_GREEN)[OK] Docker resources cleaned$(COLOR_RESET)"

clean-all: clean clean-venv clean-docker ## Clean everything

# =============================================================================
# Utility
# =============================================================================

deps-update: check-venv ## Update all dependencies
	@echo "$(COLOR_BLUE)[INFO] Updating dependencies...$(COLOR_RESET)"
	$(UV) lock --upgrade
	$(UV) sync --group local --group qa
	@echo "$(COLOR_GREEN)[OK] Dependencies updated$(COLOR_RESET)"

deps-tree: check-venv ## Show dependency tree
	$(UV) tree

pre-commit: check-venv ## Run pre-commit hooks
	$(UV) run pre-commit run --all-files

# =============================================================================
# CI/CD Helpers
# =============================================================================

ci-lint: ## CI: Run linting
	$(RUFF) check $(SRC_DIR) $(TEST_DIR) --output-format=github

ci-test: ## CI: Run tests with JUnit output
	$(PYTEST) $(TEST_DIR) \
		--junitxml=junit.xml \
		--cov=$(SRC_DIR) \
		--cov-report=xml \
		--cov-fail-under=$(COV_MIN)

ci-build: ## CI: Build Docker image
	$(DOCKER_COMPOSE) -f $(BUILD_IT_COMPOSE_FILE) build --no-cache

# =============================================================================
# Default Target
# =============================================================================

.DEFAULT_GOAL := help
