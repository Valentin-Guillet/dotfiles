#!/usr/bin/env bash

main() {
    local repeat=""
    local root=0
    local send_vim=0
    local read_args=1
    while [ $read_args = 1 ]
    do
        read_args=0
        if [ "$1" = "-r" ]
        then
            repeat="-r"
            read_args=1
            shift
        fi
        if [ "$1" = "-n" ]
        then
            root=1
            read_args=1
            shift
        fi
        if [ "$1" = "-v" ]
        then
            send_vim=1
            read_args=1
            shift
        fi
    done

    local is_single_ssh="[ \$(tmux list-panes | wc -l) = 1 ] && [ \$(tmux display-message -p '#{pane_current_command}') = ssh ]"
    if [ $send_vim = 1 ]
    then
        local is_vim="ps -o state= -o comm= -t \$(tmux display-message -p '#{pane_tty}') | grep -iqE '^[^TXZ ]+ +(\S+\/)?g?(view|n?vim?x?)(diff)?\$'"

        is_single_ssh="$is_single_ssh || $is_vim"
    fi

    if [ $root = 1 ]
    then
        tmux bind-key -n $repeat $1 if-shell "$is_single_ssh" "send-keys ${1//$/\\$}" "$2"
    else
        tmux bind-key $repeat $1 if-shell "$is_single_ssh" "send-prefix ; send-keys $1" "$2"
    fi
}

main "$@"
