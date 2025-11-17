#!/usr/bin/env bash

# Plugin to manage tmux sessions with a few commands

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

main() {
    tmux bind T new-session
    tmux bind X switch-client -n 2>/dev/null \; kill-session
    tmux bind @ run "$CURRENT_DIR/scripts/promote_pane.sh '#{session_name}' '#{pane_id}'"

    tmux bind \< command-prompt -p "(rename-session)" -I "#S" "if-shell \"[ -z '%1' ]\" \"rename-session '#{s/\\\\$//:session_id}'\" \"rename-session '%%%'\""

    tmux bind -n M-9 switch-client -p
    tmux bind -n M-0 switch-client -n

    tmux bind -n M-\( run "$CURRENT_DIR/scripts/move_window_to_session.sh '#{session_name}' '#{window_id}' 'reverse'"
    tmux bind -n M-\) run "$CURRENT_DIR/scripts/move_window_to_session.sh '#{session_name}' '#{window_id}'"

    tmux set-option -g remain-on-exit on
    tmux set-hook -g pane-died 'run "~/.config/tmux/plugins/session-manager/scripts/hook_pane_died.sh \"#{session_name}\" \"#{pane_id}\" \"#{session_windows}\" \"#{window_panes}\""'
}

main
