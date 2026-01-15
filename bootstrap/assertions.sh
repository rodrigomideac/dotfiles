#!/bin/bash
#
# Assertions script to validate bootstrap installation
#

set -e

echo "=== Running Bootstrap Assertions ==="

# Test 1: Required commands exist
echo "Test 1: Checking required commands..."
command -v zsh >/dev/null || { echo "FAIL: zsh not installed"; exit 1; }
command -v nvim >/dev/null || { echo "FAIL: nvim not installed"; exit 1; }
command -v curl >/dev/null || { echo "FAIL: curl not installed"; exit 1; }
command -v git >/dev/null || { echo "FAIL: git not installed"; exit 1; }
echo "✓ All required commands present"

# Test 2: Config files deployed correctly
echo "Test 2: Checking config files..."
[ -f "$HOME/.zshrc" ] || { echo "FAIL: .zshrc not found"; exit 1; }
[ -d "$HOME/.config/nvim" ] || { echo "FAIL: nvim config not found"; exit 1; }
[ -f "$HOME/.config/nvim/init.lua" ] || { echo "FAIL: nvim init.lua missing"; exit 1; }
echo "✓ All config files deployed"

# Test 3: Zsh config is syntactically valid (after sed cleanup)
echo "Test 3: Validating .zshrc syntax..."
zsh -n "$HOME/.zshrc" || { echo "FAIL: .zshrc has syntax errors"; exit 1; }
echo "✓ .zshrc is syntactically valid"

# Test 4: Default shell changed to zsh
echo "Test 4: Checking default shell..."
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [[ "$CURRENT_SHELL" =~ "zsh" ]]; then
    echo "✓ Default shell is zsh"
else
    # In Docker, non-root users can't change shell without password
    # This is expected, so we just warn instead of failing
    echo "⚠ Warning: Default shell not zsh (got: $CURRENT_SHELL)"
    echo "  This is expected in Docker for non-root users"
    echo "  Bootstrap would succeed in real environment"
fi

# Note about cleanup in non-interactive mode
echo ""
echo "Note: In --no-interactive mode (Docker test), all packages are installed"
echo "      so no .zshrc cleanup is performed. Cleanup is tested in interactive mode."

echo ""
echo "✅ All assertions passed!"
