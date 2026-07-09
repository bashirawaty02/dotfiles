#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# Helpers
###############################################################################

pull_repo() {
    local repo="$1"
    if [[ -d "$repo/.git" ]]; then
        git -C "$repo" pull --ff-only
    fi
}

###############################################################################
# BIN
###############################################################################

mkdir -p "$HOME/bin"

# FASD
if [[ ! -x "$HOME/bin/fasd" ]]; then
    git clone https://github.com/clvv/fasd.git /tmp/fasd
    (
        cd /tmp/fasd
        PREFIX="$HOME" make install
    )
fi

# FZF
if [[ ! -x "$HOME/.fzf/bin/fzf" ]]; then
    git clone https://github.com/junegunn/fzf.git "$HOME/.fzf"
    yes | "$HOME/.fzf/install"
fi

# diff-so-fancy
if [[ ! -x "$HOME/bin/diff-so-fancy" ]]; then
    curl -fsSL \
        -o "$HOME/bin/diff-so-fancy" \
        https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
    chmod +x "$HOME/bin/diff-so-fancy"
fi

###############################################################################
# TMUX
###############################################################################

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
pull_repo "$HOME/.tmux/plugins/tpm"

###############################################################################
# ZSH / PREZTO
###############################################################################

if [[ ! -d "${ZDOTDIR:-$HOME}/.zprezto" ]]; then
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

    setopt EXTENDED_GLOB
    for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
        ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
    done
fi

(
    cd "${ZDOTDIR:-$HOME}/.zprezto"
    git pull
    git submodule update --init --recursive
)

mkdir -p "$HOME/.zsh"

# Fast Syntax Highlighting
if [[ ! -d "$HOME/.zsh/fast-syntax-highlighting" ]]; then
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
        "$HOME/.zsh/fast-syntax-highlighting"
fi
pull_repo "$HOME/.zsh/fast-syntax-highlighting"

###############################################################################
# NEOVIM
###############################################################################

NVIM="$HOME/.neovim"
mkdir -p "$NVIM"

# Install fallback AppImage if nvim is missing
if ! command -v nvim >/dev/null; then
    mkdir -p "$NVIM/bin"
    (
        cd "$NVIM/bin"
        curl -fsSL -O https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
        chmod u+x nvim.appimage
        mv nvim.appimage nvim
    )
fi

# Python environment for Neovim
if [[ ! -d "$NVIM/py3" ]]; then
    python3 -m venv "$NVIM/py3"
    PIP="$NVIM/py3/bin/pip"
    "$PIP" install --upgrade pip
    "$PIP" install neovim
    "$PIP" install 'python-language-server[all]'
    "$PIP" install pylint isort jedi flake8
    "$PIP" install black yapf
fi

# Node environment for Neovim
if [[ ! -d "$NVIM/node" ]]; then
    mkdir -p "$NVIM/node"
    NODE_SCRIPT="/tmp/install-node.sh"
    curl -fsSL install-node.now.sh/lts -o "$NODE_SCRIPT"
    chmod +x "$NODE_SCRIPT"
    PREFIX="$NVIM/node" "$NODE_SCRIPT" -y
    PATH="$NVIM/node/bin:$PATH"
    npm install -g neovim
fi

###############################################################################
# RUST
###############################################################################

if [[ ! -d "$HOME/.rustup" ]]; then
    curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y
fi

# Install useful cargo tools
CARGO="$HOME/.cargo/bin/cargo"
for crate in bat fd-find ripgrep exa tealdeer procs ytop hyperfine bandwhich; do
    "$CARGO" install "$crate" || true
done
