#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

main() {
    tmux bind T new-session
    tmux bind X run "$CURRENT_DIR/scripts/kill_session.sh '#{session_id}'"
    tmux bind @ run "$CURRENT_DIR/scripts/promote_pane.sh '#{session_name}' '#{pane_id}'"

    tmux bind \< command-prompt -I "#S" "rename-session '%%'"

    tmux bind -n M-9 switch-client -p
    tmux bind -n M-0 switch-client -n

    tmux bind -n M-\( run "$CURRENT_DIR/scripts/move_window_to_session.sh '#{session_name}' '#{window_id}' 'reverse'"
    tmux bind -n M-\) run "$CURRENT_DIR/scripts/move_window_to_session.sh '#{session_name}' '#{window_id}'"

    tmux set-option -g remain-on-exit on
    # tmux set-option -g detach-on-destroy off
    tmux set-hook -g pane-died 'run "~/.config/tmux/plugins/session-manager/scripts/hook_pane_died.sh \"#{pane_id}\" \"#{session_windows}\" \"#{window_panes}\""'
}

main
