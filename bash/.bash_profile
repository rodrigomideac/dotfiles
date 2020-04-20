#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
export PROMPT_COMMAND="pwd > /tmp/whereami"


export PATH="$HOME/.cargo/bin:$PATH"
