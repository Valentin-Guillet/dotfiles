#!/usr/bin/env bash

main() {
    local SESS_FILE="/tmp/vim_switch.vim"
    rm -f "$SESS_FILE"

    local vim_pid=$(ps -o pid:1=,state:1=,comm:1= -t $(tmux display-message -p '#{pane_tty}') | grep -iE '^([0-9]+) [^TXZ ]+ (\S+/)?g?(view|n?vim?x?)(diff)?$' | cut -d' ' -f1)
    [ -z "$vim_pid" ] && return

    kill -s USR1 "$vim_pid"

    # Refresh so that vim processes signal
    tmux send-key 
    sleep 0.01

    # Wait for session file to be created (timeout at 250ms)
    for i in {0..4}; do
        [ -f "$SESS_FILE" ] && break
        sleep 0.050
    done
    [ ! -s "$SESS_FILE" ] && return

    tmux send-key nvim Space -S Space "$SESS_FILE" Enter
}

main
