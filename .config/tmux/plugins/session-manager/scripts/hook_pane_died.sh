#!/usr/bin/env bash

# global vars passed to the script as arguments
PANE_ID="$1"
NB_WINDOWS="$2"
NB_PANES="$3"


main() {
    local list_sessions_detached=( $(tmux ls -F '#{?session_attached,,#{session_name}}') )
    echo "${list_sessions_detached[@]}" > /tmp/yo
    
    if [ "$NB_WINDOWS" -gt 1 -o "$NB_PANES" -gt 1 -o "${#list_sessions_detached[@]}" -eq 0 ]; then
        tmux kill-pane
        return 0
    else
        tmux switch-client -t "${list_sessions_detached[0]}"
        tmux kill-pane -t "$PANE_ID"
    fi
}

main
