#!/usr/bin/env bash

# global vars passed to the script as arguments
CURRENT_SESSION_NAME="$1"
CURRENT_PANE_ID="$2"

main() {
    local number_of_panes=$(tmux list-panes -s -t "$CURRENT_SESSION_NAME" | wc -l | tr -d ' ')
    if [ "$number_of_panes" -eq 1 ]; then
        tmux display-message "Can't promote with only one pane in session"
        return 0
    fi

    local session_name="$(tmux new-session -d -P)"
    local new_session_pane_id="$(tmux list-panes -t "$session_name" -F '#{pane_id}')"
    tmux join-pane -s "$CURRENT_PANE_ID" -t "$new_session_pane_id"
    tmux kill-pane -t "$new_session_pane_id"
    tmux switch-client -t "$session_name"
}

main
