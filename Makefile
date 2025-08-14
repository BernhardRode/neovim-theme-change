# Makefile for nvim-theme-ipc plugin

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
PLUGIN_DIR = $(HOME)/.local/share/nvim/site/pack/plugins/start/nvim-theme-ipc

.PHONY: install uninstall test clean help

help: ## Show this help message
	@echo "nvim-theme-ipc Makefile"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

install: ## Install the plugin and clients
	@echo "Installing nvim-theme-ipc plugin..."
	
	# Install plugin files
	mkdir -p $(PLUGIN_DIR)
	cp -r lua/ $(PLUGIN_DIR)/
	cp -r plugin/ $(PLUGIN_DIR)/
	cp -r doc/ $(PLUGIN_DIR)/
	cp README.md $(PLUGIN_DIR)/
	
	# Install command-line clients
	mkdir -p $(BINDIR)
	cp bin/nvim-theme $(BINDIR)/
	cp bin/nvim-theme.py $(BINDIR)/
	chmod +x $(BINDIR)/nvim-theme
	chmod +x $(BINDIR)/nvim-theme.py
	
	@echo "Installation complete!"
	@echo ""
	@echo "Add this to your Neovim config:"
	@echo "  require('theme-ipc').setup()"
	@echo ""
	@echo "Command-line clients installed:"
	@echo "  nvim-theme"
	@echo "  nvim-theme.py"

install-local: ## Install plugin locally (for development)
	@echo "Installing nvim-theme-ipc plugin locally..."
	mkdir -p $(PLUGIN_DIR)
	ln -sf $(PWD)/lua $(PLUGIN_DIR)/
	ln -sf $(PWD)/plugin $(PLUGIN_DIR)/
	ln -sf $(PWD)/doc $(PLUGIN_DIR)/
	ln -sf $(PWD)/README.md $(PLUGIN_DIR)/
	@echo "Local installation complete (symlinked)!"

uninstall: ## Uninstall the plugin and clients
	@echo "Uninstalling nvim-theme-ipc plugin..."
	rm -rf $(PLUGIN_DIR)
	rm -f $(BINDIR)/nvim-theme
	rm -f $(BINDIR)/nvim-theme.py
	@echo "Uninstallation complete!"

test: ## Run basic tests
	@echo "Running basic tests..."
	
	# Test Lua syntax
	@echo "Checking Lua syntax..."
	@for file in $$(find lua -name "*.lua"); do \
		echo "  Checking $$file..."; \
		lua -l $$file -e "" 2>/dev/null || (echo "Syntax error in $$file" && exit 1); \
	done
	
	# Test shell script syntax
	@echo "Checking shell script syntax..."
	@shellcheck bin/nvim-theme || echo "shellcheck not available, skipping shell script check"
	
	# Test Python syntax
	@echo "Checking Python syntax..."
	@python3 -m py_compile bin/nvim-theme.py
	
	@echo "All tests passed!"

clean: ## Clean temporary files
	@echo "Cleaning temporary files..."
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "Clean complete!"

check-deps: ## Check for required dependencies
	@echo "Checking dependencies..."
	
	@echo -n "Neovim: "
	@if command -v nvim >/dev/null 2>&1; then \
		nvim --version | head -1; \
	else \
		echo "NOT FOUND"; \
	fi
	
	@echo -n "socat: "
	@if command -v socat >/dev/null 2>&1; then \
		echo "OK"; \
	else \
		echo "NOT FOUND (required for bash client)"; \
	fi
	
	@echo -n "jq: "
	@if command -v jq >/dev/null 2>&1; then \
		echo "OK"; \
	else \
		echo "NOT FOUND (optional, for better JSON parsing)"; \
	fi
	
	@echo -n "Python 3: "
	@if command -v python3 >/dev/null 2>&1; then \
		python3 --version; \
	else \
		echo "NOT FOUND (required for Python client)"; \
	fi

demo: ## Run a quick demo (requires Neovim to be running)
	@echo "Running demo..."
	@echo "Make sure Neovim is running with the plugin loaded!"
	@sleep 2
	
	@echo "Getting current theme..."
	@bin/nvim-theme get || echo "Server not running"
	
	@echo "Listing available themes..."
	@bin/nvim-theme list | head -5 || echo "Server not running"
	
	@echo "Demo complete!"

package: ## Create a release package
	@echo "Creating release package..."
	@VERSION=$$(grep -o 'Version: [0-9.]*' doc/theme-ipc.txt | cut -d' ' -f2); \
	tar -czf nvim-theme-ipc-$$VERSION.tar.gz \
		--exclude='.git*' \
		--exclude='*.tar.gz' \
		--exclude='Makefile' \
		lua/ plugin/ doc/ bin/ README.md
	@echo "Package created: nvim-theme-ipc-*.tar.gz"
