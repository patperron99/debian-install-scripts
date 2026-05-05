# Load environment variables from .env file (API keys, tokens)
[[ -f ~/.env ]] && export $(grep -v '^#' ~/.env | xargs)

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

stty -ixon

# ─── ALIASES ──────────────────────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -al --color=auto'
alias df='df -h'
alias free='free -h'
alias myip="ip -f inet address | grep inet | grep -v 'lo$' | cut -d ' ' -f 6,13 && curl -s ifconfig.me && echo ' (external)'"
alias x="exit"
alias reload='source ~/.bashrc'
alias ff="fastfetch"
alias v=tmux_nvim
alias kick=tmux_ssh

# Git
alias gp="git push -u origin main"
alias gsave="git commit -m 'save'"
alias gs="git status"
alias gc="git clone"

# Grep
alias egrep='grep --color=auto'

# ─── PATH & ENVIRONMENT ───────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/scripts:$PATH"
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
export VISUAL=nvim
export EDITOR=nvim

# ─── NORD PROMPT ──────────────────────────────────────────────────────────────
FROST_2='\[\e[38;2;129;161;193m\]'
FROST_3='\[\e[38;2;94;129;172m\]'
SNOW_STORM_2='\[\e[38;2;236;239;244m\]'
AURORA_RED='\[\e[38;2;211;134;155m\]'
AURORA_ORANGE='\[\e[38;2;235;137;91m\]'
AURORA_YELLOW='\[\e[38;2;235;174;97m\]'
AURORA_GREEN='\[\e[38;2;197;232;178m\]'
AURORA_PURPLE='\[\e[38;2;191;97;106m\]'
AURORA_BLUE='\[\e[38;2;116;185;255m\]'
RESET='\[\e[0m\]'

SEPARATOR=""
BRANCH=""
PYTHON=""
ERROR="✗"
OK="✓"

parse_git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

get_virtual_env() {
    [[ -n "$VIRTUAL_ENV" ]] && echo "$(basename "$VIRTUAL_ENV")"
}

set_prompt() {
    local EXIT="$?"

    PS1="\n${AURORA_BLUE}┌─${RESET}"
    PS1+="${AURORA_PURPLE}\u${SNOW_STORM_2}@${FROST_2}\h${RESET}"
    PS1+="${AURORA_BLUE} ${SEPARATOR}${RESET}"
    PS1+="${AURORA_GREEN} \w${RESET}"

    if git rev-parse --git-dir >/dev/null 2>&1; then
        PS1+="${AURORA_BLUE} ${SEPARATOR}${RESET}"
        PS1+="${AURORA_ORANGE} ${BRANCH} $(parse_git_branch)${RESET}"
    fi

    if [[ -n "$(get_virtual_env)" ]]; then
        PS1+="${AURORA_BLUE} ${SEPARATOR}${RESET}"
        PS1+="${AURORA_YELLOW} ${PYTHON} $(get_virtual_env)${RESET}"
    fi

    PS1+="${AURORA_BLUE} ${SEPARATOR}${RESET}"
    if [[ $EXIT != 0 ]]; then
        PS1+="${AURORA_RED} ${ERROR} ${EXIT}${RESET}"
    else
        PS1+="${AURORA_GREEN} ${OK}${RESET}"
    fi

    PS1+="\n${AURORA_BLUE}└─❯${RESET} "
}

PROMPT_COMMAND=set_prompt

# ─── TMUX HELPERS ─────────────────────────────────────────────────────────────
tmux_ssh() {
    local tab_name="${1:-$(basename "$(pwd)")}"
    local session="ssh-session"
    tmux has-session -t "$session" 2>/dev/null || tmux new-session -d -s "$session"
    tmux new-window -t "$session" -n "$tab_name" "ssh $1"
    tmux attach-session -t "$session"
}

tmux_nvim() {
    local tab_name="${1:-$(basename "$(pwd)")}"
    local session="neovim-session"
    tmux has-session -t "$session" 2>/dev/null || tmux new-session -d -s "$session"
    tmux new-window -t "$session" -n "$tab_name" "nvim $1"
    tmux attach-session -t "$session"
}

# ─── BASH COMPLETION ──────────────────────────────────────────────────────────
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        . /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        . /etc/bash_completion
    fi
fi
