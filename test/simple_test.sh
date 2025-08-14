#!/bin/bash
# Simple test script for nvim-theme-ipc plugin

cd "$(dirname "$0")/.."

echo "Testing nvim-theme-ipc plugin..."
echo

# Test 1: Check file structure
echo "✓ Checking file structure..."
required_files=(
    "lua/theme-ipc/init.lua"
    "plugin/theme-ipc.lua"
    "doc/theme-ipc.txt"
    "README.md"
    "bin/nvim-theme"
    "bin/nvim-theme.py"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (missing)"
        exit 1
    fi
done

# Test 2: Check Lua syntax
echo
echo "✓ Checking Lua syntax..."
if lua -e "loadfile('lua/theme-ipc/init.lua')" 2>/dev/null; then
    echo "  ✓ lua/theme-ipc/init.lua"
else
    echo "  ✗ lua/theme-ipc/init.lua (syntax error)"
    exit 1
fi

# Test 3: Check Python syntax
echo
echo "✓ Checking Python syntax..."
if python3 -m py_compile bin/nvim-theme.py 2>/dev/null; then
    echo "  ✓ bin/nvim-theme.py"
else
    echo "  ✗ bin/nvim-theme.py (syntax error)"
    exit 1
fi

# Test 4: Check shell script syntax
echo
echo "✓ Checking shell script syntax..."
if bash -n bin/nvim-theme 2>/dev/null; then
    echo "  ✓ bin/nvim-theme"
else
    echo "  ✗ bin/nvim-theme (syntax error)"
    exit 1
fi

# Test 5: Check executable permissions
echo
echo "✓ Checking executable permissions..."
executables=("bin/nvim-theme" "bin/nvim-theme.py")
for exe in "${executables[@]}"; do
    if [[ -x "$exe" ]]; then
        echo "  ✓ $exe"
    else
        echo "  ✗ $exe (not executable)"
        exit 1
    fi
done

# Test 6: Test client help
echo
echo "✓ Testing client help..."
if ./bin/nvim-theme help >/dev/null 2>&1; then
    echo "  ✓ bash client help works"
else
    echo "  ✗ bash client help failed"
    exit 1
fi

if python3 ./bin/nvim-theme.py --help >/dev/null 2>&1; then
    echo "  ✓ python client help works"
else
    echo "  ✗ python client help failed"
    exit 1
fi

echo
echo "🎉 All tests passed! Plugin is ready to use."
echo
echo "To install:"
echo "  make install"
echo
echo "To test with Neovim:"
echo "  1. Add to your Neovim config: require('theme-ipc').setup()"
echo "  2. Start Neovim"
echo "  3. Run: ./bin/nvim-theme status"
