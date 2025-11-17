#!/usr/bin/env bash

# global vars passed to the script as arguments
CURRENT_SESSION_NAME="$1"
CURRENT_WINDOW_ID="$2"
DIRECTION="$3"

main() {
    # List sessions in reverse mode to use the fact that bash arrays wrap negative indexes (`array[-1]`)
    local list_sessions=( $(tmux list-sessions -F "#{session_name}" | sort | if [ "$DIRECTION" = "reverse" ]; then cat; else tac; fi) )

    # If only one session, can't move pane
    if [ ${#list_sessions[@]} -eq 1 ]; then
        tmux display-message "No other session to move the window to!"
        return 0
    fi

    for ((i=0; i<${#list_sessions[@]}; ++i)); do
        if [ "${list_sessions[$i]}" = "$CURRENT_SESSION_NAME" ]; then
            local prev_session="${list_sessions[$i-1]}"
            break
        fi
    done

    tmux switch-client -t "$prev_session"
    tmux move-window -s "$CURRENT_WINDOW_ID"
}

main
