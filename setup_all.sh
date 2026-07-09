#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Shell Detection
###############################################################################
CURRENT_SHELL="$(ps -p $$ -o comm=)"
echo ">>> Detected shell: $CURRENT_SHELL"

is_bash=false
is_zsh=false

case "$CURRENT_SHELL" in
    bash) is_bash=true ;;
    zsh)  is_zsh=true ;;
    *)    echo ">>> Unknown shell ($CURRENT_SHELL). Using bash-safe mode."
          is_bash=true ;;
esac

###############################################################################
# OS Detection
###############################################################################
OS="unknown"
DISTRO="unknown"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO="$ID"
    fi

    if grep -qi microsoft /proc/version 2>/dev/null; then
        OS="wsl"
    fi

elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
fi

echo ">>> Detected OS: $OS"
echo ">>> Detected Distro: $DISTRO"

###############################################################################
# Helpers
###############################################################################
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
# Install CLI tools (OS-aware)
###############################################################################
mkdir -p "$HOME/bin"

install_pkg() {
    case "$OS" in
        macos)
            brew install "$1" || true
            ;;
        linux|wsl)
            case "$DISTRO" in
                ubuntu|debian)
                    sudo apt-get update -y
                    sudo apt-get install -y "$1"
                    ;;
                fedora)
                    sudo dnf install -y "$1"
                    ;;
                centos|rhel)
                    sudo yum install -y "$1"
                    ;;
                arch)
                    sudo pacman -Sy --noconfirm "$1"
                    ;;
                *)
                    echo ">>> Unknown Linux distro. Install $1 manually."
                    ;;
            esac
            ;;
        *)
            echo ">>> Unknown OS. Install $1 manually."
            ;;
    esac
}

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

# diff-so-fancy (fixed URL)
if [[ ! -x "$HOME/bin/diff-so-fancy" ]]; then
    curl -fsSL \
        -o "$HOME/bin/diff-so-fancy" \
        https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/diff-so-fancy
    chmod +x "$HOME/bin/diff-so-fancy"
fi

###############################################################################
# TMUX + TPM
###############################################################################
install_pkg tmux

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
pull_repo "$HOME/.tmux/plugins/tpm"

###############################################################################
# ZSH + PREZTO + Fast Syntax Highlighting
###############################################################################
install_pkg zsh

if [[ ! -d "${ZDOTDIR:-$HOME}/.zprezto" ]]; then
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

    if $is_zsh; then
        # Run Zsh-only globbing inside a Zsh subprocess
        zsh -c '
            setopt EXTENDED_GLOB
            ZDOTDIR="${ZDOTDIR:-$HOME}"
            for rcfile in "$ZDOTDIR/.zprezto/runcoms/"^README.md(.N); do
                ln -s "$rcfile" "$ZDOTDIR/.${rcfile:t}"
            done
        '
    else
        # Bash-safe globbing
        shopt -s extglob
        for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/!(*README.md); do
            ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile##*/}"
        done
    fi
fi

(
    cd "${ZDOTDIR:-$HOME}/.zprezto"
    git pull
    git submodule update --init --recursive
)



###############################################################################
# Neovim (source build + Python + Node)
###############################################################################
install_pkg ninja-build
install_pkg gettext
install_pkg curl
install_pkg git

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
install_pkg python3
install_pkg python3-venv || true

if [[ ! -d "$NVIM/py3" ]]; then
    python3 -m venv "$NVIM/py3"
    PIP="$NVIM/py3/bin/pip"
    "$PIP" install --upgrade pip
    "$PIP" install neovim 'python-language-server[all]' pylint isort jedi flake8 black yapf
fi

# Node environment (fixed installer)
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
install_pkg stow

PROGRAMS=(alias bash env git python scripts stow tmux vim zsh)

mkdir -p "$HOME/.vim/undodir"

for program in "${PROGRAMS[@]}"; do
    echo ">>> Stowing $program"
    stow -v --target="$HOME" "$program"
done

echo ">>> Setup complete!"
