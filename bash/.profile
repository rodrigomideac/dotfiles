[ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || export QT_QPA_PLATFORMTHEME="qt5ct"

# SSH agent is socket-activated by the stock ssh-agent.socket user unit
# SSH_AUTH_SOCK is set in .zshrc pointing to the systemd socket

export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/clion-2019.2.5/bin:$PATH"

