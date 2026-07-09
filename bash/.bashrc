### ─────────────────────────────────────────────
### Environment Setup
### ─────────────────────────────────────────────
[ -f "$HOME/.env" ] && source "$HOME/.env"

### ─────────────────────────────────────────────
### Prompt (PS1)
### ─────────────────────────────────────────────
# Use a single PS1 definition instead of two
# Add exit code indicator + git branch + color cleanup

# Colors
RESET="

\[\033[0m\]

"
CYAN="

\[\033[36m\]

"
BLUE="

\[\033[34m\]

"
GREEN="

\[\033[32m\]

"
RED="

\[\033[31m\]

"

# Show exit code only when non‑zero
exit_code() {
    code=$?
    [ $code -ne 0 ] && echo -e "${RED}✘ $code${RESET}"
}

# Git branch function
parse_git_branch() {
    git branch --show-current 2>/dev/null
}

PS1="\$(exit_code)${CYAN}[${BLUE}\u@\h ${GREEN}\W${CYAN}]\$(parse_git_branch)${RESET} \$ "

### ─────────────────────────────────────────────
### Aliases
### ─────────────────────────────────────────────
[ -f "$HOME/.aliases" ] && source "$HOME/.aliases"

### ─────────────────────────────────────────────
### Extra Tools
### ─────────────────────────────────────────────
[ -f "$HOME/.bin/tmuxinator.bash" ] && source "$HOME/.bin/tmuxinator.bash"
[ -f "$HOME/.fzf.bash" ] && source "$HOME/.fzf.bash"

### ─────────────────────────────────────────────
### History
### ─────────────────────────────────────────────
# Ignore jrnl commands
HISTIGNORE="$HISTIGNORE:jrnl *"

# Better history settings
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend

### ─────────────────────────────────────────────
### Bash Completion
### ─────────────────────────────────────────────

# Load system bash-completion if available
if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# Optional: load user-specific completions
[ -d "$HOME/.bash_completion.d" ] && \
    for f in "$HOME/.bash_completion.d"/*.bash; do
        [ -f "$f" ] && source "$f"
    done


