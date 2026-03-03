#!/usr/bin/env bash
dir="$1"
mode="${2:-prompt}"

if [ "$mode" = "fzf" ]; then
    cmd=$(compgen -c | sort -u | fzf --prompt="> ")
else
    printf "> "
    read -r cmd
fi

if [ -n "$cmd" ]; then
    pane=$(tmux new-window -P -F '#{pane_id}' -c "$dir" -n "$cmd")
    tmux send-keys -t "$pane" "$cmd" Enter
fi
