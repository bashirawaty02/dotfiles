#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Remove macOS junk
###############################################################################
find . -name ".DS_Store" -exec rm -f {} \;

###############################################################################
# Programs to stow
###############################################################################
PROGRAMS=(alias bash env git python scripts stow tmux vim zsh)

###############################################################################
# Backup directory
###############################################################################
OLD_DOTFILES="dotfile_bk_$(date -u +"%Y%m%d%H%M%S")"
mkdir -p "$OLD_DOTFILES"

backup_if_exists() {
    local path="$1"
    if [[ -e "$path" ]]; then
        echo ">>> Backing up $path → $OLD_DOTFILES"
        mv "$path" "$OLD_DOTFILES/"
    fi
}

###############################################################################
# Backup common dotfiles
###############################################################################
backup_if_exists "$HOME/.bash_profile"
backup_if_exists "$HOME/.bashrc"
backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.gitconfig"
backup_if_exists "$HOME/.tmux.conf"
backup_if_exists "$HOME/.profile"

###############################################################################
# Backup Prezto runcoms
###############################################################################
if [[ -d "$HOME/.zprezto/runcoms" ]]; then
    for f in "$HOME"/.zprezto/runcoms/z*; do
        [[ -e "$f" ]] && mv "$f" "$OLD_DOTFILES/"
    done
fi

###############################################################################
# Vim directories
###############################################################################
mkdir -p "$HOME/.vim/undodir"

###############################################################################
# Stow dotfiles
###############################################################################
for program in "${PROGRAMS[@]}"; do
    echo ">>> Stowing $program"
    stow -v --target="$HOME" "$program"
done

echo ">>> Done!"
