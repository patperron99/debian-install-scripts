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

# ─── PROMPT ───────────────────────────────────────────────────────────────────
_t=$(cat "$HOME/.local/share/current-theme" 2>/dev/null || echo "gruvbox")
case "$_t" in
  catppuccin-mocha)
    _PC_BORDER='\[\e[38;2;137;180;250m\]'   # blue
    _PC_USER='\[\e[38;2;203;166;247m\]'     # mauve
    _PC_HOST='\[\e[38;2;137;180;250m\]'     # blue
    _PC_AT='\[\e[38;2;205;214;244m\]'       # text
    _PC_PATH='\[\e[38;2;166;227;161m\]'     # green
    _PC_GIT='\[\e[38;2;250;179;135m\]'      # peach
    _PC_VENV='\[\e[38;2;249;226;175m\]'     # yellow
    _PC_ERROR='\[\e[38;2;243;139;168m\]'    # red
    _PC_OK='\[\e[38;2;166;227;161m\]'       # green
    ;;
  tokyo-night)
    _PC_BORDER='\[\e[38;2;122;162;247m\]'   # blue
    _PC_USER='\[\e[38;2;187;154;247m\]'     # purple
    _PC_HOST='\[\e[38;2;122;162;247m\]'     # blue
    _PC_AT='\[\e[38;2;192;202;245m\]'       # text
    _PC_PATH='\[\e[38;2;158;206;106m\]'     # green
    _PC_GIT='\[\e[38;2;255;158;100m\]'      # orange
    _PC_VENV='\[\e[38;2;224;175;104m\]'     # yellow
    _PC_ERROR='\[\e[38;2;247;118;142m\]'    # red
    _PC_OK='\[\e[38;2;158;206;106m\]'       # green
    ;;
  nord)
    _PC_BORDER='\[\e[38;2;129;161;193m\]'   # frost2
    _PC_USER='\[\e[38;2;191;97;106m\]'      # aurora red
    _PC_HOST='\[\e[38;2;94;129;172m\]'      # frost3
    _PC_AT='\[\e[38;2;236;239;244m\]'       # snow storm
    _PC_PATH='\[\e[38;2;163;190;140m\]'     # aurora green
    _PC_GIT='\[\e[38;2;208;135;112m\]'      # aurora orange
    _PC_VENV='\[\e[38;2;235;203;139m\]'     # aurora yellow
    _PC_ERROR='\[\e[38;2;191;97;106m\]'     # aurora red
    _PC_OK='\[\e[38;2;163;190;140m\]'       # aurora green
    ;;
  rose-pine)
    _PC_BORDER='\[\e[38;2;156;207;216m\]'   # foam
    _PC_USER='\[\e[38;2;196;167;231m\]'     # iris
    _PC_HOST='\[\e[38;2;156;207;216m\]'     # foam
    _PC_AT='\[\e[38;2;224;222;244m\]'       # text
    _PC_PATH='\[\e[38;2;235;188;186m\]'     # rose
    _PC_GIT='\[\e[38;2;246;193;119m\]'      # gold
    _PC_VENV='\[\e[38;2;246;193;119m\]'     # gold
    _PC_ERROR='\[\e[38;2;235;111;146m\]'    # love
    _PC_OK='\[\e[38;2;156;207;216m\]'       # foam
    ;;
  *)  # gruvbox (default)
    _PC_BORDER='\[\e[38;2;69;133;136m\]'    # aqua
    _PC_USER='\[\e[38;2;250;189;47m\]'      # yellow bright
    _PC_HOST='\[\e[38;2;131;165;152m\]'     # aqua bright
    _PC_AT='\[\e[38;2;235;219;178m\]'       # fg
    _PC_PATH='\[\e[38;2;184;187;38m\]'      # green bright
    _PC_GIT='\[\e[38;2;254;128;25m\]'       # orange bright
    _PC_VENV='\[\e[38;2;250;189;47m\]'      # yellow bright
    _PC_ERROR='\[\e[38;2;251;73;52m\]'      # red bright
    _PC_OK='\[\e[38;2;184;187;38m\]'        # green bright
    ;;
esac
unset _t
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

    PS1="\n${_PC_BORDER}┌─${RESET}"
    PS1+="${_PC_USER}\u${_PC_AT}@${_PC_HOST}\h${RESET}"
    PS1+="${_PC_BORDER} ${SEPARATOR}${RESET}"
    PS1+="${_PC_PATH} \w${RESET}"

    if git rev-parse --git-dir >/dev/null 2>&1; then
        PS1+="${_PC_BORDER} ${SEPARATOR}${RESET}"
        PS1+="${_PC_GIT} ${BRANCH} $(parse_git_branch)${RESET}"
    fi

    if [[ -n "$(get_virtual_env)" ]]; then
        PS1+="${_PC_BORDER} ${SEPARATOR}${RESET}"
        PS1+="${_PC_VENV} ${PYTHON} $(get_virtual_env)${RESET}"
    fi

    PS1+="${_PC_BORDER} ${SEPARATOR}${RESET}"
    if [[ $EXIT != 0 ]]; then
        PS1+="${_PC_ERROR} ${ERROR} ${EXIT}${RESET}"
    else
        PS1+="${_PC_OK} ${OK}${RESET}"
    fi

    PS1+="\n${_PC_BORDER}└─❯${RESET} "
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
