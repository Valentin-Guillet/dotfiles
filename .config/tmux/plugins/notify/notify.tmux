#!/usr/bin/env bash

main() {
    local curr_tty=$(tmux display-message -p '#{pane_tty}')
    local bash_state=$(ps -t "$curr_tty" -o stat= | head -n 1)

    if [[ "$bash_state" == *+ ]]
    then
        tmux display-message 'No running process to monitor'
        return
    fi

    local pane_id=$(tmux display-message -p '#{pane_id}')
    local notif_msg=$(tmux display-message -p 'Command \`#{pane_current_command}` in window [#S:#I###P] has finished')

    # Cancel if already running -- check the pane fg option
    if [[ $(tmux show-options -t $pane_id -p window-active-style) ]]
    then
        mkdir -p $HOME/.cache/tmux/
        touch $HOME/.cache/tmux/notify_$pane_id
        return
    fi

    tmux set-option -t $pane_id -p window-active-style fg=red
    tmux set-option -t $pane_id -p window-style fg=red

    while [[ "$bash_state" != *+ ]]
    do
        sleep 0.2

        # Check if user canceled tracking by creating the "flag" file
        [ -f $HOME/.cache/tmux/notify_$pane_id ] && break
        bash_state=$(ps -t "$curr_tty" -o stat= | head -n 1)
    done

    tmux set-option -t $pane_id -p -u window-active-style
    tmux set-option -t $pane_id -p -u window-style

    if [ -f $HOME/.cache/tmux/notify_$pane_id ]; then
        rm $HOME/.cache/tmux/notify_$pane_id
        tmux display-message 'Tracking cancelled'
    else
        notify-send "Process finished" "$notif_msg"
    fi
}

main
