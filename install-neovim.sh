#!/usr/bin/env zsh
set -euo pipefail

NEOVIM_DIR="$HOME/.neovim"
BUILD_DIR="/tmp/neovim-src"

echo ">>> Building Neovim into $NEOVIM_DIR"

###############################################################################
# Clone Neovim source
###############################################################################
if [[ -d "$BUILD_DIR" ]]; then
    echo ">>> Removing old build directory"
    rm -rf "$BUILD_DIR"
fi

echo ">>> Cloning Neovim repository"
git clone --depth=1 https://github.com/neovim/neovim.git "$BUILD_DIR"

###############################################################################
# Build Neovim
###############################################################################
echo ">>> Building Neovim (Release mode)"
(
    cd "$BUILD_DIR"
    make CMAKE_BUILD_TYPE=Release
)

###############################################################################
# Install Neovim
###############################################################################
echo ">>> Installing Neovim into $NEOVIM_DIR"
(
    cd "$BUILD_DIR"
    make CMAKE_INSTALL_PREFIX="$NEOVIM_DIR" install
)

echo ">>> Neovim installed successfully at: $NEOVIM_DIR/bin/nvim"
