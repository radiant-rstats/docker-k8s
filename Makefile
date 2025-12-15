# Makefile for rsm-msba-k8s Docker multi-platform builds

# Configuration
IMAGE_NAME := vnijs/rsm-msba-k8s
PLATFORMS := linux/amd64,linux/arm64
BUILDER_NAME := multiplatform-builder
VERSION ?= latest
DOCKERFILE := rsm-msba-k8s/Dockerfile

# Detect current platform
CURRENT_PLATFORM := $(shell uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help
help: ## Show this help message
	@echo "$(GREEN)rsm-msba-k8s Multi-Platform Build System$(NC)"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC)"
	@echo "  make [target] [VERSION=x.x.x]"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make build               # Build and push multi-platform image with version 'latest'"
	@echo "  make build VERSION=v1.0  # Build and push multi-platform image with version 'v1.0'"
	@echo "  make test                # Build local test image without pushing"
	@echo "  make login               # Login to Docker Hub"
	@echo ""

.PHONY: check-docker
check-docker: ## Check if Docker is running and buildx is available
	@echo "$(GREEN)Checking Docker setup...$(NC)"
	@docker info > /dev/null 2>&1 || (echo "$(RED)Error: Docker is not running$(NC)" && exit 1)
	@docker buildx version > /dev/null 2>&1 || (echo "$(RED)Error: Docker buildx is not available$(NC)" && exit 1)
	@echo "$(GREEN)✓ Docker and buildx are available$(NC)"

.PHONY: setup-builder
setup-builder: check-docker ## Setup buildx multi-platform builder
	@echo "$(GREEN)Setting up buildx builder...$(NC)"
	@if ! docker buildx ls | grep -q "$(BUILDER_NAME)"; then \
		echo "$(YELLOW)Creating new builder: $(BUILDER_NAME)$(NC)"; \
		docker buildx create --name $(BUILDER_NAME) --driver docker-container --use; \
	else \
		echo "$(GREEN)Using existing builder: $(BUILDER_NAME)$(NC)"; \
		docker buildx use $(BUILDER_NAME); \
	fi
	@echo "$(GREEN)Bootstrapping builder...$(NC)"
	@docker buildx inspect --bootstrap

.PHONY: login
login: ## Login to Docker Hub (uses DOCKER_TOKEN or prompts for credentials)
	@echo "$(GREEN)Logging in to Docker Hub...$(NC)"
	@if [ -n "$$DOCKER_TOKEN" ]; then \
		echo "$(GREEN)Using DOCKER_TOKEN environment variable$(NC)"; \
		echo "$$DOCKER_TOKEN" | docker login --username vnijs --password-stdin; \
	elif [ -n "$$DOCKER_PASSWORD" ] && [ -n "$$DOCKER_USERNAME" ]; then \
		echo "$(GREEN)Using DOCKER_USERNAME and DOCKER_PASSWORD$(NC)"; \
		echo "$$DOCKER_PASSWORD" | docker login --username "$$DOCKER_USERNAME" --password-stdin; \
	else \
		echo "$(YELLOW)No credentials found in environment, running interactive login$(NC)"; \
		docker login; \
	fi

.PHONY: test-auth
test-auth: ## Test Docker Hub authentication
	@echo "$(GREEN)Testing Docker Hub authentication...$(NC)"
	@docker manifest inspect $(IMAGE_NAME):latest > /dev/null 2>&1 && \
		echo "$(GREEN)✓ Authentication working - you have access to $(IMAGE_NAME)$(NC)" || \
		echo "$(YELLOW)⚠ Cannot access repository - login may be required$(NC)"

.PHONY: test
test: setup-builder ## Build local test image for current platform (no push)
	@echo "$(GREEN)Building test image for linux/$(CURRENT_PLATFORM)...$(NC)"
	@mkdir -p build-logs
	@docker buildx build \
		--platform linux/$(CURRENT_PLATFORM) \
		--tag $(IMAGE_NAME):test-build \
		--build-arg DOCKERHUB_VERSION=test \
		--load \
		--progress=plain \
		-f $(DOCKERFILE) \
		. 2>&1 | tee build-logs/test-build_$$(date +%Y%m%d_%H%M%S).log
	@echo "$(GREEN)✓ Test build complete: $(IMAGE_NAME):test-build$(NC)"

.PHONY: build
build: setup-builder test-auth ## Build and push multi-platform image
	@echo "$(GREEN)Building multi-platform image: $(IMAGE_NAME):$(VERSION)$(NC)"
	@echo "$(YELLOW)Platforms: $(PLATFORMS)$(NC)"
	@echo "$(YELLOW)This may take 30-60 minutes...$(NC)"
	@mkdir -p build-logs
	@docker buildx build \
		--platform $(PLATFORMS) \
		--tag $(IMAGE_NAME):$(VERSION) \
		--tag $(IMAGE_NAME):latest \
		--build-arg DOCKERHUB_VERSION=$(VERSION) \
		--push \
		--progress=plain \
		-f $(DOCKERFILE) \
		. 2>&1 | tee build-logs/multiplatform-build_$$(date +%Y%m%d_%H%M%S).log
	@echo "$(GREEN)✓ Build complete and pushed to Docker Hub$(NC)"
	@echo "$(GREEN)Image: $(IMAGE_NAME):$(VERSION)$(NC)"
	@docker buildx imagetools inspect $(IMAGE_NAME):$(VERSION)

.PHONY: build-no-cache
build-no-cache: setup-builder test-auth ## Build and push multi-platform image without cache
	@echo "$(GREEN)Building multi-platform image without cache: $(IMAGE_NAME):$(VERSION)$(NC)"
	@echo "$(YELLOW)Platforms: $(PLATFORMS)$(NC)"
	@echo "$(YELLOW)This may take 30-60 minutes...$(NC)"
	@mkdir -p build-logs
	@docker buildx build \
		--platform $(PLATFORMS) \
		--tag $(IMAGE_NAME):$(VERSION) \
		--tag $(IMAGE_NAME):latest \
		--build-arg DOCKERHUB_VERSION=$(VERSION) \
		--no-cache \
		--push \
		--progress=plain \
		-f $(DOCKERFILE) \
		. 2>&1 | tee build-logs/multiplatform-build_$$(date +%Y%m%d_%H%M%S).log
	@echo "$(GREEN)✓ Build complete and pushed to Docker Hub$(NC)"
	@echo "$(GREEN)Image: $(IMAGE_NAME):$(VERSION)$(NC)"
	@docker buildx imagetools inspect $(IMAGE_NAME):$(VERSION)

.PHONY: inspect
inspect: ## Inspect the multi-platform manifest for a version
	@echo "$(GREEN)Inspecting $(IMAGE_NAME):$(VERSION)$(NC)"
	@docker buildx imagetools inspect $(IMAGE_NAME):$(VERSION)

.PHONY: clean-builder
clean-builder: ## Remove the buildx builder
	@echo "$(YELLOW)Removing buildx builder: $(BUILDER_NAME)$(NC)"
	@docker buildx rm $(BUILDER_NAME) || true
	@echo "$(GREEN)✓ Builder removed$(NC)"

.PHONY: clean-logs
clean-logs: ## Clean up build log files
	@echo "$(YELLOW)Cleaning build logs...$(NC)"
	@rm -rf build-logs/*
	@echo "$(GREEN)✓ Logs cleaned$(NC)"

.PHONY: clean-test-images
clean-test-images: ## Remove local test images
	@echo "$(YELLOW)Removing test images...$(NC)"
	@docker rmi $(IMAGE_NAME):test-build 2>/dev/null || true
	@echo "$(GREEN)✓ Test images removed$(NC)"

.PHONY: clean
clean: clean-test-images clean-logs ## Clean up test images and logs

.PHONY: status
status: ## Show current build environment status
	@echo "$(GREEN)Build Environment Status$(NC)"
	@echo "$(YELLOW)========================$(NC)"
	@echo "Image Name:       $(IMAGE_NAME)"
	@echo "Version:          $(VERSION)"
	@echo "Platforms:        $(PLATFORMS)"
	@echo "Current Platform: linux/$(CURRENT_PLATFORM)"
	@echo "Dockerfile:       $(DOCKERFILE)"
	@echo ""
	@echo "$(YELLOW)Docker Status:$(NC)"
	@docker info | grep -E "Operating System|OSType|Architecture" || true
	@echo ""
	@echo "$(YELLOW)Buildx Builders:$(NC)"
	@docker buildx ls || echo "$(RED)buildx not available$(NC)"
	@echo ""
	@echo "$(YELLOW)Authentication:$(NC)"
	@docker info 2>/dev/null | grep "Username:" || echo "Not logged in"
