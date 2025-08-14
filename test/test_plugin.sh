#!/bin/bash
# Test script for nvim-theme-ipc plugin

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_RUN++))
    log_info "Running test: $test_name"
    
    if eval "$test_command"; then
        log_success "$test_name"
        return 0
    else
        log_error "$test_name"
        return 1
    fi
}

# Test functions
test_lua_syntax() {
    local lua_files
    mapfile -t lua_files < <(find ../lua -name "*.lua" 2>/dev/null || true)
    
    if [[ ${#lua_files[@]} -eq 0 ]]; then
        log_warning "No Lua files found"
        return 1
    fi
    
    for file in "${lua_files[@]}"; do
        # Use luac to check syntax, or fallback to loading the file
        if command -v luac >/dev/null 2>&1; then
            if ! luac -p "$file" >/dev/null 2>&1; then
                log_error "Syntax error in $file"
                return 1
            fi
        else
            # Fallback: try to load the file and check for syntax errors
            if ! lua -e "loadfile('$file')" >/dev/null 2>&1; then
                log_error "Syntax error in $file"
                return 1
            fi
        fi
    done
    
    return 0
}

test_python_syntax() {
    local python_files
    mapfile -t python_files < <(find ../bin -name "*.py" 2>/dev/null || true)
    
    if [[ ${#python_files[@]} -eq 0 ]]; then
        log_warning "No Python files found"
        return 1
    fi
    
    for file in "${python_files[@]}"; do
        if ! python3 -m py_compile "$file" 2>/dev/null; then
            log_error "Syntax error in $file"
            return 1
        fi
    done
    
    return 0
}

test_shell_syntax() {
    local shell_files
    mapfile -t shell_files < <(find ../bin -name "nvim-theme" -o -name "*.sh" 2>/dev/null || true)
    
    if [[ ${#shell_files[@]} -eq 0 ]]; then
        log_warning "No shell files found"
        return 1
    fi
    
    for file in "${shell_files[@]}"; do
        if ! bash -n "$file" 2>/dev/null; then
            log_error "Syntax error in $file"
            return 1
        fi
    done
    
    return 0
}

test_client_help() {
    if [[ -x "../bin/nvim-theme" ]]; then
        ../bin/nvim-theme help >/dev/null 2>&1
    else
        log_warning "nvim-theme client not found or not executable"
        return 1
    fi
}

test_python_client_help() {
    if [[ -x "../bin/nvim-theme.py" ]]; then
        python3 ../bin/nvim-theme.py --help >/dev/null 2>&1
    else
        log_warning "nvim-theme.py client not found or not executable"
        return 1
    fi
}

test_dependencies() {
    local deps=("socat" "jq" "python3")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warning "Missing optional dependencies: ${missing[*]}"
        return 1
    fi
    
    return 0
}

test_file_structure() {
    local required_files=(
        "../lua/theme-ipc/init.lua"
        "../plugin/theme-ipc.lua"
        "../doc/theme-ipc.txt"
        "../README.md"
        "../bin/nvim-theme"
        "../bin/nvim-theme.py"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Required file missing: $file"
            return 1
        fi
    done
    
    return 0
}

test_executable_permissions() {
    local executables=(
        "../bin/nvim-theme"
        "../bin/nvim-theme.py"
    )
    
    for exe in "${executables[@]}"; do
        if [[ ! -x "$exe" ]]; then
            log_error "File not executable: $exe"
            return 1
        fi
    done
    
    return 0
}

# Integration tests (require running Neovim instance)
test_server_communication() {
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
    local socket_file="$cache_dir/theme_socket"
    
    if [[ ! -f "$socket_file" ]]; then
        log_warning "No running Neovim instance with theme-ipc found"
        return 1
    fi
    
    local socket_path
    socket_path=$(cat "$socket_file")
    
    if [[ ! -S "$socket_path" ]]; then
        log_warning "Socket file exists but socket is not active"
        return 1
    fi
    
    # Test basic communication
    if command -v socat >/dev/null 2>&1; then
        local response
        response=$(echo '{"action":"get_theme"}' | socat - UNIX-CONNECT:"$socket_path" 2>/dev/null || true)
        
        if [[ -n "$response" ]]; then
            return 0
        else
            log_error "No response from server"
            return 1
        fi
    else
        log_warning "socat not available for socket testing"
        return 1
    fi
}

test_client_status() {
    if [[ -x "../bin/nvim-theme" ]]; then
        ../bin/nvim-theme status >/dev/null 2>&1
    else
        log_warning "nvim-theme client not available"
        return 1
    fi
}

# Main test runner
main() {
    log_info "Starting nvim-theme-ipc plugin tests..."
    echo
    
    # Syntax tests
    run_test "Lua syntax check" "test_lua_syntax"
    run_test "Python syntax check" "test_python_syntax"
    run_test "Shell syntax check" "test_shell_syntax"
    
    # Structure tests
    run_test "File structure check" "test_file_structure"
    run_test "Executable permissions" "test_executable_permissions"
    
    # Client tests
    run_test "Bash client help" "test_client_help"
    run_test "Python client help" "test_python_client_help"
    
    # Dependency tests
    run_test "Dependencies check" "test_dependencies"
    
    # Integration tests (optional)
    if [[ "${1:-}" == "--integration" ]]; then
        log_info "Running integration tests (requires running Neovim)..."
        run_test "Server communication" "test_server_communication"
        run_test "Client status check" "test_client_status"
    fi
    
    # Summary
    echo
    log_info "Test Summary:"
    echo "  Tests run: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "Some tests failed!"
        exit 1
    fi
}

# Change to test directory
cd "$(dirname "$0")"

main "$@"
