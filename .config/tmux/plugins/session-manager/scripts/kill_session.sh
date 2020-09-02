#!/usr/bin/env bash

# global vars passed to the script as arguments
CURRENT_SESSION_ID="$1"

main() {
    local number_of_sessions="$(tmux list-sessions | wc -l | sed 's/ //g')"

    # If only one session
	if [ "$number_of_sessions" -eq 1 ]; then
		return 0

    else
        tmux switch-client -n
	fi

	tmux kill-session -t "$CURRENT_SESSION_ID"
}

main
