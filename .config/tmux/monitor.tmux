
new-window -n 'Monitor' -c $HOME

select-pane -t 1
send-keys 'htop' Enter

split-window -v
send-keys "watch nvidia-smi" Enter

split-window -h
send-keys "watch sensors" Enter

select-pane -t 1

