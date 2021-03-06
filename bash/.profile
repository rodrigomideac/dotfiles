[ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || export QT_QPA_PLATFORMTHEME="qt5ct"

# start keyring to prevent ssh asking password more than once
if [ -n "$DESKTOP_SESSION" ];then
    eval $(gnome-keyring-daemon --start)
    export SSH_AUTH_SOCK
fi

export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/clion-2019.2.5/bin:$PATH"

