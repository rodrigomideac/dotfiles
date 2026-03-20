# zmodload zsh/zprof

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

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

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

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

alias copy-stdout="xclip -selection clipboard"
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/.local/share/gem/ruby/3.4.0/bin
export PATH=$PATH:$HOME/devtools

## SSH Agent to store passkeys
if [[ -n "$XDG_RUNTIME_DIR" ]]; then
    SSH_ENV="$XDG_RUNTIME_DIR/ssh-agent.env"
    if [[ -f "$SSH_ENV" ]]; then
        source "$SSH_ENV" >/dev/null
    else
        ssh-agent > "$SSH_ENV"
        source "$SSH_ENV" >/dev/null
    fi
fi

## NVM for Node.js
[[ -f /usr/share/nvm/init-nvm.sh ]] && source /usr/share/nvm/init-nvm.sh

## Source work-aliasrc so it can be stored in a private manner
[[ -f ~/.work-aliasrc ]] && source ~/.work-aliasrc

# source /opt/kube-ps1/kube-ps1.sh
(( $+functions[kube_ps1] )) && PROMPT='$(kube_ps1)'$PROMPT

# export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR"/ssh-agent.socket
autoload -U compinit
compinit
_comp_options+=(globdots)
command -v jj &>/dev/null && source <(jj util completion zsh)

#source /usr/share/fzf/key-bindings.zsh
export FLYCTL_INSTALL="$HOME/.fly"
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

export PATH="${PATH}:${HOME}/.local/share/gem/ruby/3.3.0"
export PATH="${PATH}:/usr/lib/ruby/gems/3.3.0"
command -v mise &>/dev/null && eval "$(mise activate zsh)"

alias rgf='rg --files | rg'
#. $HOME/esp/esp-idf/export.sh
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"

# . "$HOME/.atuin/bin/env"

#eval "$(atuin init zsh)"
command -v atuin &>/dev/null && eval "$(atuin init zsh --disable-up-arrow)"
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

alias vim="nvim"
alias nano="nvim"
alias nf="nvim ."
alias nscala="JAVA_HOME=$HOME/.local/share/mise/installs/java/temurin-21.0.8+9.0.LTS nvim ."
alias nclaude="nvim ~/.claude/"
alias nnotes="nvim ~/dev/notes"
alias ntodo="nvim ~/dev/notes/todo.md"
alias nn="cd ~/.config/nvim && nf"
alias nd="nvim ~/dev-pessoal/dotfiles/"
alias cnvim="cd ~/.config/nvim && claude"
alias cniri="cd ~/.config/niri && claude"
alias npost="nvim $HOME/dev-pessoal/some-words"
alias njst="nvim $HOME/dev-pessoal/dk"
export EDITOR=nvim
alias mr="mise run"
alias xc="xclip -selection clipboard"
alias wakeup-cubo="wol c8:7f:54:d0:ed:a1"
alias wakeup-pc="wol 00:d8:61:36:88:58"
alias wakeup-pc="wol 00:d8:61:36:88:58"
eval "$(zoxide init zsh)"
alias jst="just --working-directory $HOME/dev-pessoal/dk --justfile $HOME/dev-pessoal/dk/justfile"
alias idf="cd ~/esp/esp-idf && . ./export.sh && cd -"
alias cdan="claude --dangerously-skip-permissions"
alias cdanc="claude --dangerously-skip-permissions -c"

feature() {
    local base_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" || { echo "Not in a git repo"; return 1; }
    local branch="${1:-wt-$(head -c 4 /dev/urandom | xxd -p)}"
    local repo_root="$(git rev-parse --show-toplevel)"
    local wt_path="${repo_root}/.claude/worktrees/${branch}"

    if [[ -d "$wt_path" ]]; then
        cd "$wt_path"
        claude -r "$branch"
        return
    fi

    mkdir -p "$(dirname "$wt_path")"
    git worktree add -b "$branch" "$wt_path" "$base_branch" || return 1

    echo "Worktree created:"
    echo "  branch: $branch"
    echo "  path:   $wt_path"
    echo "  base:   $base_branch"
    echo ""
    echo "To merge back: feature-merge $branch"
    cd "$wt_path"
    mise trust
    dev "$wt_path" "$branch"
    # cdan "/rename $branch"
}

feature-merge() {
    local branch="$1"
    if [[ -z "$branch" ]]; then
        echo "Usage: gwt-merge <worktree-branch>"
        echo ""
        echo "Active worktrees:"
        git worktree list
        return 1
    fi

    local repo_root="$(git rev-parse --show-toplevel)"
    local wt_path="${repo_root}/.claude/worktrees/${branch}"

    if [[ ! -d "$wt_path" ]]; then
        echo "Worktree not found at: $wt_path"
        return 1
    fi

    git merge "$branch" || { echo "Merge failed — resolve conflicts and run: git worktree remove '$wt_path' && git branch -d '$branch'"; return 1; }
    git worktree remove "$wt_path"
    git branch -d "$branch"
    echo "Merged and cleaned up '$branch'"
}

# Tmux dev session: dev [directory]
dev() {
    local dir="${1:-.}"
    dir="$(builtin cd "$dir" > /dev/null 2>&1 && pwd)" || { echo "Directory not found: $1"; return 1; }
    local name="$(basename "$dir" | tr '.' '_' | tr -cd '[:alnum:]_-')"
    echo "DIR: $dir"
    echo "NAME: $name"

    if tmux has-session -t "$name" 2>/dev/null; then
        if [[ -n "$TMUX" ]]; then tmux switch-client -t "$name"
        else tmux attach-session -t "$name"; fi
        return
    fi

    tmux new-session -d -s "$name" -c "$dir"
    tmux rename-window -t "$name:0" "shell"
    tmux send-keys -t "$name:0" "builtin cd '$dir'" C-m

    tmux new-window -t "$name:8" -n "editor" -c "$dir"
    tmux send-keys -t "$name:8" "builtin cd '$dir' && nvim ." C-m

    tmux new-window -t "$name:9" -n "claude" -c "$dir"
    echo "RECEIVED: $2"
    if [[ -n "$2" ]]; then
        tmux send-keys -t "$name:9" "builtin cd '$dir' && claude --dangerously-skip-permissions '/rename $2'" C-m
    else
        tmux send-keys -t "$name:9" "builtin cd '$dir' && claude --dangerously-skip-permissions" C-m
    fi

    tmux select-window -t "$name:8"
    if [[ -n "$TMUX" ]]; then tmux switch-client -t "$name"
    else tmux attach-session -t "$name"; fi
}

dev-close() {
    if [[ -z "$TMUX" ]]; then
        echo "Not in a tmux session"
        return 1
    fi
    local session="$(tmux display-message -p '#S')"
    tmux kill-session -t "$session"
}

# G1GC somehow is broken with sbt builds
export SBT_OPTS="-Xmx2G -Xss2M -XX:MaxMetaspaceSize=512M \
    -XX:+UseParallelGC \
    -XX:ParallelGCThreads=4 \
    -Duser.timezone=GMT"


