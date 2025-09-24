# Roblox Script Bundler Makefile
# Automatically bundles all script.lua files from grow-a-garden folder
# Output goes to output folder

# Variables
TOOLS_DIR := $(shell pwd)
PROJECT_ROOT := $(shell dirname $(TOOLS_DIR))
INPUT_DIR := $(PROJECT_ROOT)/grow-a-garden
OUTPUT_DIR := $(PROJECT_ROOT)/output
BUNDLER_SCRIPT := $(TOOLS_DIR)/bundler.js
BUNDLE_SHELL := $(TOOLS_DIR)/bundle.sh

# Find all script.lua files in grow-a-garden and subdirectories
SCRIPT_FILES := $(shell find $(INPUT_DIR) -name "script.lua" -type f)
OUTPUT_FILES := $(patsubst $(INPUT_DIR)/%.lua,$(OUTPUT_DIR)/%-bundled.lua,$(SCRIPT_FILES))

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m # No Color

# Default target
.PHONY: all
all: setup bundle

# Help target
.PHONY: help
help:
	@echo "$(BLUE)🚀 Roblox Script Bundler Makefile$(NC)"
	@echo "=================================="
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@echo "  $(GREEN)all$(NC)           - Setup and bundle all scripts (local-only)"
	@echo "  $(GREEN)bundle$(NC)        - Bundle all script.lua files (local-only)"
	@echo "  $(GREEN)bundle-github$(NC) - Bundle using GitHub only"
	@echo "  $(GREEN)bundle-hybrid$(NC) - Bundle with local first, GitHub fallback"
	@echo "  $(GREEN)setup$(NC)         - Create output directory"
	@echo "  $(GREEN)clean$(NC)         - Remove output directory"
	@echo "  $(GREEN)list$(NC)          - List all found script files"
	@echo "  $(GREEN)watch$(NC)         - Watch for changes and auto-bundle"
	@echo "  $(GREEN)help$(NC)          - Show this help message"
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make                 # Bundle with local files only"
	@echo "  make bundle-github   # Bundle from GitHub only"
	@echo "  make bundle-hybrid   # Bundle local first, GitHub fallback"
	@echo "  make clean bundle    # Clean and bundle (local-only)"
	@echo "  make list            # Show found scripts"
	@echo "  make watch           # Auto-bundle on changes"

# Setup output directory
.PHONY: setup
setup:
	@echo "$(BLUE)📁 Setting up output directory...$(NC)"
	@mkdir -p $(OUTPUT_DIR)
	@echo "$(GREEN)✅ Output directory created: $(OUTPUT_DIR)$(NC)"

# List all found script files
.PHONY: list
list:
	@echo "$(BLUE)📋 Found script files:$(NC)"
	@echo "$(YELLOW)Input directory: $(INPUT_DIR)$(NC)"
	@echo "$(YELLOW)Output directory: $(OUTPUT_DIR)$(NC)"
	@echo ""
	@if [ -z "$(SCRIPT_FILES)" ]; then \
		echo "$(RED)❌ No script.lua files found in $(INPUT_DIR)$(NC)"; \
	else \
		for file in $(SCRIPT_FILES); do \
			rel_path=$$(realpath --relative-to=$(INPUT_DIR) $$file); \
			output_file=$(OUTPUT_DIR)/$$(echo $$rel_path | sed 's/\.lua$$/-bundled.lua/'); \
			echo "$(CYAN)📄 $$rel_path$(NC) → $(GREEN)$$(basename $$output_file)$(NC)"; \
		done; \
	fi

# Bundle all scripts
.PHONY: bundle
bundle: setup $(OUTPUT_FILES)
	@echo "$(GREEN)🎉 All scripts bundled successfully!$(NC)"
	@echo "$(YELLOW)📊 Bundle Summary:$(NC)"
	@ls -la $(OUTPUT_DIR)/*.lua 2>/dev/null | while read line; do \
		size=$$(echo $$line | awk '{print $$5}'); \
		name=$$(echo $$line | awk '{print $$9}'); \
		echo "$(CYAN)  📦 $$(basename $$name): $(GREEN)$$(numfmt --to=iec $$size)$(NC)"; \
	done || echo "$(RED)❌ No bundled files found$(NC)"

# Pattern rule to bundle individual scripts
$(OUTPUT_DIR)/%-bundled.lua: $(INPUT_DIR)/%.lua
	@echo "$(YELLOW)🔄 Bundling $(CYAN)$<$(NC) → $(GREEN)$@$(NC)"
	@mkdir -p $(dir $@)
	@if [ -f "$(BUNDLER_SCRIPT)" ]; then \
		node $(BUNDLER_SCRIPT) "$<" "$@" --local-only || { \
			echo "$(RED)❌ Bundling failed for $<$(NC)"; \
			exit 1; \
		}; \
	else \
		echo "$(RED)❌ Bundler script not found: $(BUNDLER_SCRIPT)$(NC)"; \
		exit 1; \
	fi

# Clean output directory
.PHONY: clean
clean:
	@echo "$(YELLOW)🧹 Cleaning output directory...$(NC)"
	@rm -rf $(OUTPUT_DIR)
	@echo "$(GREEN)✅ Output directory cleaned$(NC)"

# Watch for changes and auto-bundle
.PHONY: watch
watch:
	@echo "$(BLUE)👀 Watching for changes in $(INPUT_DIR)...$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	@if command -v inotifywait >/dev/null 2>&1; then \
		while true; do \
			inotifywait -r -e modify,create,delete $(INPUT_DIR) --include='.*\.lua$$' 2>/dev/null && { \
				echo "$(CYAN)🔄 Changes detected, rebuilding...$(NC)"; \
				$(MAKE) bundle; \
			}; \
		done; \
	elif command -v fswatch >/dev/null 2>&1; then \
		fswatch -o $(INPUT_DIR) | while read event; do \
			echo "$(CYAN)🔄 Changes detected, rebuilding...$(NC)"; \
			$(MAKE) bundle; \
		done; \
	else \
		echo "$(RED)❌ File watching requires inotifywait (Linux) or fswatch (macOS)$(NC)"; \
		echo "$(YELLOW)Install with:$(NC)"; \
		echo "  Ubuntu/Debian: sudo apt install inotify-tools"; \
		echo "  macOS: brew install fswatch"; \
		exit 1; \
	fi

# Development target - bundle and copy to clipboard (if available)
.PHONY: dev
dev: bundle
	@echo "$(PURPLE)🔧 Development mode$(NC)"
	@if command -v xclip >/dev/null 2>&1; then \
		latest_bundle=$$(ls -t $(OUTPUT_DIR)/*-bundled.lua | head -1); \
		if [ -f "$$latest_bundle" ]; then \
			cat "$$latest_bundle" | xclip -selection clipboard; \
			echo "$(GREEN)📋 Latest bundle copied to clipboard$(NC)"; \
		fi; \
	fi

# Install dependencies (if needed)
.PHONY: install
install:
	@echo "$(BLUE)📦 Installing dependencies...$(NC)"
	@if [ -f "package.json" ]; then \
		npm install; \
		echo "$(GREEN)✅ Dependencies installed$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  No package.json found, skipping npm install$(NC)"; \
	fi

# Force rebuild all bundles
.PHONY: rebuild
rebuild: clean bundle

# Show project info
.PHONY: info
info:
	@echo "$(BLUE)📊 Project Information$(NC)"
	@echo "======================"
	@echo "$(YELLOW)Tools Directory:$(NC) $(TOOLS_DIR)"
	@echo "$(YELLOW)Project Root:$(NC) $(PROJECT_ROOT)"
	@echo "$(YELLOW)Input Directory:$(NC) $(INPUT_DIR)"
	@echo "$(YELLOW)Output Directory:$(NC) $(OUTPUT_DIR)"
	@echo "$(YELLOW)Bundler Script:$(NC) $(BUNDLER_SCRIPT)"
	@echo ""
	@echo "$(YELLOW)Node.js Version:$(NC) $$(node --version 2>/dev/null || echo 'Not installed')"
	@echo "$(YELLOW)NPM Version:$(NC) $$(npm --version 2>/dev/null || echo 'Not installed')"

# Validate environment
.PHONY: check
check:
	@echo "$(BLUE)🔍 Environment Check$(NC)"
	@echo "===================="
	@error_count=0; \
	if ! command -v node >/dev/null 2>&1; then \
		echo "$(RED)❌ Node.js not found$(NC)"; \
		error_count=$$((error_count + 1)); \
	else \
		echo "$(GREEN)✅ Node.js found: $$(node --version)$(NC)"; \
	fi; \
	if [ ! -f "$(BUNDLER_SCRIPT)" ]; then \
		echo "$(RED)❌ Bundler script not found: $(BUNDLER_SCRIPT)$(NC)"; \
		error_count=$$((error_count + 1)); \
	else \
		echo "$(GREEN)✅ Bundler script found$(NC)"; \
	fi; \
	if [ ! -d "$(INPUT_DIR)" ]; then \
		echo "$(RED)❌ Input directory not found: $(INPUT_DIR)$(NC)"; \
		error_count=$$((error_count + 1)); \
	else \
		echo "$(GREEN)✅ Input directory found$(NC)"; \
	fi; \
	if [ $$error_count -eq 0 ]; then \
		echo "$(GREEN)🎉 Environment check passed!$(NC)"; \
	else \
		echo "$(RED)💥 Environment check failed with $$error_count errors$(NC)"; \
		exit 1; \
	fi

# Quick bundle - just the main script (local-only)
.PHONY: quick
quick:
	@main_script="$(INPUT_DIR)/script.lua"; \
	if [ -f "$$main_script" ]; then \
		echo "$(YELLOW)⚡ Quick bundling main script (local-only)...$(NC)"; \
		mkdir -p $(OUTPUT_DIR); \
		node $(BUNDLER_SCRIPT) "$$main_script" "$(OUTPUT_DIR)/main-bundled.lua" --local-only; \
		echo "$(GREEN)✅ Quick bundle complete$(NC)"; \
	else \
		echo "$(RED)❌ Main script not found: $$main_script$(NC)"; \
		exit 1; \
	fi

# Bundle with GitHub only (for comparison)
.PHONY: bundle-github
bundle-github: setup
	@echo "$(BLUE)🌐 Bundling with GitHub-only mode...$(NC)"
	@main_script="$(INPUT_DIR)/script.lua"; \
	if [ -f "$$main_script" ]; then \
		node $(BUNDLER_SCRIPT) "$$main_script" "$(OUTPUT_DIR)/script-github-bundled.lua" --github-only; \
		echo "$(GREEN)✅ GitHub bundle complete$(NC)"; \
	else \
		echo "$(RED)❌ Main script not found: $$main_script$(NC)"; \
		exit 1; \
	fi

# Bundle with hybrid mode (local first, GitHub fallback)
.PHONY: bundle-hybrid
bundle-hybrid: setup
	@echo "$(PURPLE)🔄 Bundling with hybrid mode (local + GitHub)...$(NC)"
	@main_script="$(INPUT_DIR)/script.lua"; \
	if [ -f "$$main_script" ]; then \
		node $(BUNDLER_SCRIPT) "$$main_script" "$(OUTPUT_DIR)/script-hybrid-bundled.lua"; \
		echo "$(GREEN)✅ Hybrid bundle complete$(NC)"; \
	else \
		echo "$(RED)❌ Main script not found: $$main_script$(NC)"; \
		exit 1; \
	fi

# Make sure intermediate files aren't deleted
.PRECIOUS: $(OUTPUT_FILES)

# Declare phony targets
.PHONY: all bundle setup clean list watch dev install rebuild info check quick help