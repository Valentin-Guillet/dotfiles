#!/usr/bin/env bash

# global vars passed to the script as arguments
SESSION_NAME="$1"
PANE_ID="$2"
NB_WINDOWS="$3"
NB_PANES="$4"


main() {
    local list_sessions_detached=( $(tmux list-sessions -F '#{?session_attached,,#{session_name}}') )

    if [ "$NB_WINDOWS" -eq 1 -a "$NB_PANES" -eq 1 -a "${#list_sessions_detached[@]}" -gt 0 ]; then
        local list_sessions=( $(tmux list-sessions -F '#{?session_attached,'A','D'}-#{session_name}') )
        local session_index=0
        for elt in "${list_sessions[@]}"; do
            [[ "$elt" =~ ^D- ]] && ((session_index++))
            [ "${elt:2}" = "$SESSION_NAME" ] && break
        done
        [ "$session_index" -eq "${#list_sessions_detached[@]}" ] && session_index=0

        tmux switch-client -t "${list_sessions_detached[$session_index]}"
    fi

    tmux kill-pane -t "$PANE_ID"
}

main
