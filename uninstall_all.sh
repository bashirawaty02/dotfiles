#!/usr/bin/env bash
set -euo pipefail

echo ">>> Uninstalling environment"

###############################################################################
# Remove stowed dotfiles
###############################################################################
PROGRAMS=(alias bash env git python scripts stow tmux vim zsh)

for program in "${PROGRAMS[@]}"; do
    echo ">>> Unstowing $program"
    stow -v -D --target="$HOME" "$program" || true
done

###############################################################################
# Remove Neovim
###############################################################################
rm -rf "$HOME/.neovim"

###############################################################################
# Remove CLI tools
###############################################################################
rm -f "$HOME/bin/fasd"
rm -f "$HOME/bin/diff-so-fancy"
rm -rf "$HOME/.fzf"

###############################################################################
# Remove tmux plugins
###############################################################################
rm -rf "$HOME/.tmux/plugins/tpm"

###############################################################################
# Remove Prezto + Zsh extras
###############################################################################
rm -rf "${ZDOTDIR:-$HOME}/.zprezto"
rm -rf "$HOME/.zsh/fast-syntax-highlighting"

###############################################################################
# Remove Rust toolchain
###############################################################################
rm -rf "$HOME/.rustup"
rm -rf "$HOME/.cargo"

echo ">>> Uninstall complete!"
