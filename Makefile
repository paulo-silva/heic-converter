.PHONY: help build release install uninstall clean test check fmt lint run-help all

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

# Binary name and paths
BINARY_NAME := heic2jpg
INSTALL_PATH := /usr/local/bin/$(BINARY_NAME)
RELEASE_BINARY := target/release/$(BINARY_NAME)
DEBUG_BINARY := target/debug/$(BINARY_NAME)

# Default target
help: ## Show this help message
	@echo "$(CYAN)HEIC to JPG Converter - Makefile$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

all: release ## Build release binary (default)

build: ## Build in debug mode
	@echo "$(GREEN)Building in debug mode...$(NC)"
	cargo build
	@echo "$(GREEN)Build complete: $(DEBUG_BINARY)$(NC)"

release: ## Build optimized release binary
	@echo "$(GREEN)Building in release mode (optimized)...$(NC)"
	cargo build --release
	@echo "$(GREEN)Build complete: $(RELEASE_BINARY)$(NC)"

install: release ## Install binary to /usr/local/bin
	@echo "$(GREEN)Installing $(BINARY_NAME) to $(INSTALL_PATH)...$(NC)"
	@if [ -w "/usr/local/bin" ]; then \
		cp $(RELEASE_BINARY) $(INSTALL_PATH); \
	else \
		echo "$(YELLOW)Requires sudo privileges...$(NC)"; \
		sudo cp $(RELEASE_BINARY) $(INSTALL_PATH); \
	fi
	@echo "$(GREEN)Installation complete!$(NC)"
	@echo "Run '$(BINARY_NAME) --help' to get started"

uninstall: ## Remove installed binary
	@echo "$(YELLOW)Uninstalling $(BINARY_NAME) from $(INSTALL_PATH)...$(NC)"
	@if [ -f "$(INSTALL_PATH)" ]; then \
		if [ -w "/usr/local/bin" ]; then \
			rm $(INSTALL_PATH); \
		else \
			sudo rm $(INSTALL_PATH); \
		fi; \
		echo "$(GREEN)Uninstall complete$(NC)"; \
	else \
		echo "$(YELLOW)$(BINARY_NAME) is not installed$(NC)"; \
	fi

clean: ## Remove build artifacts
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	cargo clean
	@rm -rf test_output test_data/*.jpg
	@echo "$(GREEN)Clean complete$(NC)"

test: ## Run tests
	@echo "$(GREEN)Running tests...$(NC)"
	cargo test

check: ## Check code without building
	@echo "$(GREEN)Checking code...$(NC)"
	cargo check

fmt: ## Format code with rustfmt
	@echo "$(GREEN)Formatting code...$(NC)"
	cargo fmt

fmt-check: ## Check code formatting
	@echo "$(GREEN)Checking code formatting...$(NC)"
	cargo fmt -- --check

lint: ## Run clippy linter
	@echo "$(GREEN)Running clippy...$(NC)"
	cargo clippy -- -D warnings

lint-fix: ## Apply clippy suggestions automatically
	@echo "$(GREEN)Applying clippy fixes...$(NC)"
	cargo clippy --fix --allow-dirty --allow-staged

run-help: release ## Build and show help message
	@$(RELEASE_BINARY) --help

run-version: release ## Build and show version
	@$(RELEASE_BINARY) --version

bench: ## Run benchmarks (if any)
	@echo "$(GREEN)Running benchmarks...$(NC)"
	cargo bench

doc: ## Generate and open documentation
	@echo "$(GREEN)Generating documentation...$(NC)"
	cargo doc --open

deps: ## Check for outdated dependencies
	@echo "$(GREEN)Checking dependencies...$(NC)"
	@cargo tree

update: ## Update dependencies
	@echo "$(GREEN)Updating dependencies...$(NC)"
	cargo update

audit: ## Audit dependencies for security vulnerabilities
	@echo "$(GREEN)Auditing dependencies...$(NC)"
	@if command -v cargo-audit >/dev/null 2>&1; then \
		cargo audit; \
	else \
		echo "$(YELLOW)cargo-audit not found. Install with: cargo install cargo-audit$(NC)"; \
	fi

bloat: release ## Analyze binary size
	@echo "$(GREEN)Analyzing binary size...$(NC)"
	@if command -v cargo-bloat >/dev/null 2>&1; then \
		cargo bloat --release; \
	else \
		echo "$(YELLOW)cargo-bloat not found. Install with: cargo install cargo-bloat$(NC)"; \
	fi

setup: ## Install development dependencies
	@echo "$(GREEN)Installing development tools...$(NC)"
	rustup component add rustfmt clippy
	@echo "$(GREEN)Setup complete!$(NC)"

setup-libheif: ## Show instructions for installing libheif
	@echo "$(CYAN)Installing libheif dependencies:$(NC)"
	@echo ""
	@if [ "$$(uname)" = "Darwin" ]; then \
		echo "  macOS: brew install libheif"; \
	elif [ "$$(uname)" = "Linux" ]; then \
		if command -v apt-get >/dev/null 2>&1; then \
			echo "  Ubuntu/Debian: sudo apt-get install libheif-dev"; \
		elif command -v dnf >/dev/null 2>&1; then \
			echo "  Fedora: sudo dnf install libheif-devel"; \
		elif command -v yum >/dev/null 2>&1; then \
			echo "  CentOS/RHEL: sudo yum install libheif-devel"; \
		else \
			echo "  Please install libheif-dev using your package manager"; \
		fi; \
	fi
	@echo ""

quick: ## Quick check (fmt + clippy + test)
	@echo "$(GREEN)Running quick checks...$(NC)"
	@$(MAKE) fmt-check
	@$(MAKE) lint
	@$(MAKE) test
	@echo "$(GREEN)All checks passed!$(NC)"

ci: ## Run CI checks locally
	@echo "$(GREEN)Running CI checks...$(NC)"
	@$(MAKE) fmt-check
	@$(MAKE) lint
	@$(MAKE) test
	@$(MAKE) build
	@$(MAKE) release
	@echo "$(GREEN)CI checks complete!$(NC)"

size: release ## Show binary size
	@echo "$(GREEN)Binary size:$(NC)"
	@ls -lh $(RELEASE_BINARY) | awk '{print "  " $$9 ": " $$5}'
	@echo ""
	@echo "$(GREEN)Stripped size:$(NC)"
	@strip $(RELEASE_BINARY) -o /tmp/$(BINARY_NAME)_stripped 2>/dev/null && ls -lh /tmp/$(BINARY_NAME)_stripped | awk '{print "  Stripped: " $$5}' && rm /tmp/$(BINARY_NAME)_stripped || echo "  Strip not available"

watch: ## Watch for changes and rebuild
	@echo "$(GREEN)Watching for changes...$(NC)"
	@if command -v cargo-watch >/dev/null 2>&1; then \
		cargo watch -x build; \
	else \
		echo "$(YELLOW)cargo-watch not found. Install with: cargo install cargo-watch$(NC)"; \
	fi
