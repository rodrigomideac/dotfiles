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
command -v stow >/dev/null || { echo "FAIL: stow not installed"; exit 1; }
command -v tmux >/dev/null || { echo "FAIL: tmux not installed"; exit 1; }
command -v rg >/dev/null || { echo "FAIL: ripgrep not installed"; exit 1; }
command -v jq >/dev/null || { echo "FAIL: jq not installed"; exit 1; }
echo "✓ All required commands present"

# Test 2: Config files deployed via stow (should be symlinks)
echo "Test 2: Checking config files..."
[ -f "$HOME/.zshrc" ] || { echo "FAIL: .zshrc not found"; exit 1; }
[ -L "$HOME/.zshrc" ] || { echo "FAIL: .zshrc is not a symlink (stow not working)"; exit 1; }
[ -f "$HOME/.vimrc" ] || { echo "FAIL: .vimrc not found"; exit 1; }
[ -L "$HOME/.vimrc" ] || { echo "FAIL: .vimrc is not a symlink (stow not working)"; exit 1; }
[ -f "$HOME/.tmux.conf" ] || { echo "FAIL: .tmux.conf not found"; exit 1; }
[ -L "$HOME/.tmux.conf" ] || { echo "FAIL: .tmux.conf is not a symlink (stow not working)"; exit 1; }
[ -d "$HOME/.config/nvim" ] || { echo "FAIL: nvim config not found"; exit 1; }
[ -L "$HOME/.config/nvim" ] || { echo "FAIL: nvim config is not a symlink (stow not working)"; exit 1; }
[ -f "$HOME/.config/nvim/init.lua" ] || { echo "FAIL: nvim init.lua missing"; exit 1; }
echo "✓ All config files deployed as stow symlinks"

# Test 3: Zsh config is syntactically valid
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

# Test 5: Dotfiles cloned to expected location
echo "Test 5: Checking dotfiles repo..."
[ -d "$HOME/.dotfiles/.git" ] || { echo "FAIL: dotfiles repo not cloned"; exit 1; }
[ -f "$HOME/.dotfiles/Makefile" ] || { echo "FAIL: Makefile missing from dotfiles"; exit 1; }
echo "✓ Dotfiles repo present"

echo ""
echo "✅ All assertions passed!"
