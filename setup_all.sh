#!/usr/bin/env bash
set -euo pipefail

timestamp() { date -u +"%Y%m%d%H%M%S"; }

BACKUP_DIR="$HOME/dotfile_bk_$(timestamp)"
mkdir -p "$BACKUP_DIR"

backup_if_exists() {
    local path="$1"
    if [[ -e "$path" ]]; then
        echo ">>> Backing up $path"
        mv "$path" "$BACKUP_DIR/"
    fi
}

pull_repo() {
    local repo="$1"
    if [[ -d "$repo/.git" ]]; then
        git -C "$repo" pull --ff-only
    fi
}

###############################################################################
# Remove macOS junk
###############################################################################
find . -name ".DS_Store" -exec rm -f {} \;

###############################################################################
# Backup common dotfiles
###############################################################################
for f in \
    "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.zshrc" \
    "$HOME/.gitconfig" "$HOME/.tmux.conf" "$HOME/.profile"
do
    backup_if_exists "$f"
done

###############################################################################
# Backup Prezto runcoms
###############################################################################
if [[ -d "$HOME/.zprezto/runcoms" ]]; then
    for f in "$HOME"/.zprezto/runcoms/z*; do
        [[ -e "$f" ]] && mv "$f" "$BACKUP_DIR/"
    done
fi

###############################################################################
# Install CLI tools
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
# TMUX + TPM
###############################################################################
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
pull_repo "$HOME/.tmux/plugins/tpm"

###############################################################################
# ZSH + PREZTO + Fast Syntax Highlighting
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

if [[ ! -d "$HOME/.zsh/fast-syntax-highlighting" ]]; then
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
        "$HOME/.zsh/fast-syntax-highlighting"
fi
pull_repo "$HOME/.zsh/fast-syntax-highlighting"

###############################################################################
# Neovim (source build + Python + Node)
###############################################################################
NVIM="$HOME/.neovim"
mkdir -p "$NVIM"

BUILD_DIR="/tmp/neovim-src"
rm -rf "$BUILD_DIR"
git clone --depth=1 https://github.com/neovim/neovim.git "$BUILD_DIR"

(
    cd "$BUILD_DIR"
    make CMAKE_BUILD_TYPE=Release
    make CMAKE_INSTALL_PREFIX="$NVIM" install
)

# Python environment
if [[ ! -d "$NVIM/py3" ]]; then
    python3 -m venv "$NVIM/py3"
    PIP="$NVIM/py3/bin/pip"
    "$PIP" install --upgrade pip
    "$PIP" install neovim 'python-language-server[all]' pylint isort jedi flake8 black yapf
fi

# Node environment
if [[ ! -d "$NVIM/node" ]]; then
    mkdir -p "$NVIM/node"
    NODE_SCRIPT="/tmp/install-node.sh"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh -o "$NODE_SCRIPT"
    bash "$NODE_SCRIPT"
    source "$HOME/.nvm/nvm.sh"
    nvm install --lts
    npm install -g neovim
fi


###############################################################################
# Rust + Cargo utilities
###############################################################################
if [[ ! -d "$HOME/.rustup" ]]; then
    curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y
fi

CARGO="$HOME/.cargo/bin/cargo"
for crate in bat fd-find ripgrep exa tealdeer procs ytop hyperfine bandwhich; do
    "$CARGO" install "$crate" || true
done

###############################################################################
# Stow dotfiles
###############################################################################
PROGRAMS=(alias bash env git python scripts stow tmux vim zsh)

mkdir -p "$HOME/.vim/undodir"

for program in "${PROGRAMS[@]}"; do
    echo ">>> Stowing $program"
    stow -v --target="$HOME" "$program"
done

echo ">>> Setup complete!"
