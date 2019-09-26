# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
export PATH=$PATH:/home/rodrigo/devtools/JLink_Linux_V622d_x86_64
export PATH=$PATH:/home/rodrigo/devtools/yakindu-sctpro
export PATH=$PATH:/home/rodrigo/devtools/gcc-arm-none-eabi-6_2-2016q4/bin
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/home/rodrigo/devtools/pycharm-community-2019.2/bin
export PATH=$PATH:/home/rodrigo/.local/bin/
alias aws-login='~/dev/dev-setup/aws-login.sh; export AWS_PROFILE=cobli-tech'

xrandr --output eDP-1 --mode 1920x1080
xrandr --output HDMI-1 --left-of eDP-1
setxkbmap -layout br
VISUAL=vim; export VISUAL EDITOR=vim; export EDITOR
xset +fp /home/rodrigo/.local/share/fonts
xset fp rehash
