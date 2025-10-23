# zmodload zsh/zprof

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/home/rodrigo/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="agnoster"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the followiNg line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git kube-ps1)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#
#powerline-daemon -q
#. /usr/lib/python3.7/site-packages/powerline/bindings/zsh/powerline.zsh

prompt_context () { }

function chpwd() {
    ls -a
    pwd > /tmp/whereami
}

TIMEFMT=$'\n================\nCPU\t%P\nuser\t%*U\nsystem\t%*S\ntotal\t%*E'

alias vpn-usp-connect="nmcli con up VPN\ USPNet --ask"
alias copy-stdout="xclip -selection clipboard"

# System Sources
## SDKMAN for Java, Scala and SBT
# source "$HOME/.sdkman/bin/sdkman-init.sh"
source $HOME/.cargo/env
export PATH=$PATH:/usr/local/go/bin
#export GO_PATH="~/devtools/go1.18"
#export PATH=$PATH:$GO_PATH/bin
export PATH=$PATH:/home/rodrigo/devtools


## SSH Agent to store passkeys
SSH_ENV="$XDG_RUNTIME_DIR/ssh-agent.env"

# Check if we have a valid SSH agent running
if [[ -f "$SSH_ENV" ]]; then
    source "$SSH_ENV" >/dev/null
    # if ! ssh-add -l >/dev/null 2>&1; then
    #     # Agent is not accessible, start a new one
    #     ssh-agent > "$SSH_ENV"
    #     source "$SSH_ENV" >/dev/null
    # fi
else
    # No agent file exists, start a new one
    ssh-agent > "$SSH_ENV"
    source "$SSH_ENV" >/dev/null
fi

## NVM for Node.js
source /usr/share/nvm/init-nvm.sh

## Source work-aliasrc so it can be stored in a private manner
if [ -f ~/.work-aliasrc ]; then
    source ~/.work-aliasrc
else
    print "404: ~/.work-aliasrc not found."
fi

# source /opt/kube-ps1/kube-ps1.sh
PROMPT='$(kube_ps1)'$PROMPT

# export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR"/ssh-agent.socket
autoload -U compinit
compinit
_comp_options+=(globdots)
source <(jj util completion zsh)

# [[ -s "/home/rodrigo/.gvm/scripts/gvm" ]] && source "/home/rodrigo/.gvm/scripts/gvm"

#source /usr/share/fzf/key-bindings.zsh
export FLYCTL_INSTALL="/home/rodrigo/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"

_uv_run_mod() {
    if [[ "$words[2]" == "run" && "$words[CURRENT]" != -* ]]; then
        # Check if any previous argument after 'run' ends with .py
        if [[ ${words[3,$((CURRENT-1))]} =~ ".*\.py" ]]; then
            # Already have a .py file, complete any files
            _arguments '*:filename:_files'
        else
            # No .py file yet, complete only .py files
            _arguments '*:filename:_files -g "*.py"'
        fi
    else
        _uv "$@"
    fi
}
compdef _uv_run_mod uv

# Shell-GPT integration ZSH v0.2

# if [[ -n "$BUFFER" ]]; then
#     _sgpt_prev_cmd=$BUFFER
#     BUFFER+="⌛"
#     zle -I && zle redisplay
#     BUFFER=$(sgpt --shell <<< "$_sgpt_prev_cmd" --no-interaction)
#     zle end-of-line
# fi
# }
# zle -N _sgpt_zsh
# bindkey ^l _sgpt_zsh
# Shell-GPT integration ZSH v0.2

# Shell-GPT integration ZSH v0.2
# _sgpt_zsh() {
# if [[ -n "$BUFFER" ]]; then
#     _sgpt_prev_cmd=$BUFFER
#     BUFFER+="⌛"
#     zle -I && zle redisplay
#     BUFFER=$(sgpt --shell <<< "$_sgpt_prev_cmd" --no-interaction)
#     zle end-of-line
# fi
# }
# zle -N _sgpt_zsh
# bindkey ^l _sgpt_zsh
# Shell-GPT integration ZSH v0.2
#

# export GOPATH="${HOME}/go"
# export PATH="${PATH}:${GOPATH}/bin"
# export PATH="${PATH}:${HOME}/go/bin"
export PATH="${PATH}:${HOME}/.local/share/gem/ruby/3.3.0"
export PATH="${PATH}:/usr/lib/ruby/gems/3.3.0"
eval "$(mise activate zsh)"

alias rgf='rg --files | rg'
#. $HOME/esp/esp-idf/export.sh
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"

# . "$HOME/.atuin/bin/env"

#eval "$(atuin init zsh)"
eval "$(atuin init zsh --disable-up-arrow)"
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

alias vim="nvim"
alias nano="nvim"
alias nf="nvim ."
alias nclaude="nvim ~/.claude/"
alias nnotes="nvim ~/dev/notes"
alias ntodo="nvim ~/dev/notes/todo.md"
alias nn="nvim ~/.config/nvim"
alias nd="nvim ~/dev-pessoal/dotfiles/"
alias cnvim="cd ~/.config/nvim && claude"
alias cniri="cd ~/.config/niri && claude"
alias npost="nvim /home/rodrigo/dev-pessoal/some-words"
alias njst="nvim /home/rodrigo/dev-pessoal/dk"
export EDITOR=nvim
alias mr="mise run"
alias xc="xclip -selection clipboard"

xc1() {
    if [ $# -eq 0 ]; then
        echo "Usage: xc <filename>"
        return 1
    fi
    cat "$1" | xclip -selection clipboard && echo "Copied $1 to clipboard"
}
# Function to copy the current command line to the clipboard
# copy_command_to_clipboard() {
#   print -rn -- "$BUFFER" | xclip -selection clipboard
#   zle -M "Current Command copied to clipboard"
#   print_help
# }
# zle -N copy_command_to_clipboard
# bindkey '^G' copy_command_to_clipboard
#
# copy_last_command() {
#   print -z "$(fc -ln -1)" | xclip -selection clipboard
#   zle -M "Last Command copied to clipboard"
#   print_help
# }
# zle -N copy_last_command
# bindkey '^F' copy_last_command
#
# bindkey() {
#   fc -ln -1 | xargs -I {} sh -c "{}" | xclip -selection clipboard
#   zle -M "Last Output copied to clipboard"
#   print_help
# }
# zle -N copy_last_output
# bindkey '^P' copy_last_output
#
# print_help() {
#     zle -M "Keymaps:"
#     zle -M "    Ctrl+f: Copy last command"
#     zle -M "    Ctrl+g: Copy current command"
#     zle -M "    Ctrl+p: Copy last output"
# }

alias jst="just --working-directory /home/rodrigo/dev-pessoal/dk --justfile /home/rodrigo/dev-pessoal/dk/justfile"
alias idf="cd ~/esp/esp-idf && . ./export.sh && cd -"

y() {
    yazi --cwd-file /tmp/yazidir
    if [ -f /tmp/yazidir ]; then
        cd "$(cat /tmp/yazidir)"
    fi
}

# zprof
