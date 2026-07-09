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
    bash)
        is_bash=true
        ;;
    zsh)
        is_zsh=true
        ;;
    *)
        echo ">>> Unknown shell ($CURRENT_SHELL). Defaulting to bash-safe mode."
        is_bash=true
        ;;
esac

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

    # Shell-aware globbing
    if $is_zsh; then
        setopt EXTENDED_GLOB
        for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
            ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
        done
    else
        shopt -s extglob
        for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/!(*README.md); do
            ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile##*/}"
        done
    fi
fi

(
    cd "${ZDOT
