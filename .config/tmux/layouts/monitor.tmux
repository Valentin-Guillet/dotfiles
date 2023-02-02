
new-window -n 'Monitor' -c $HOME

select-pane -t 1
send-keys 'htop' Enter

split-window -v
send-keys "command -v nvidia-smi && watch nvidia-smi || exit" Enter

split-window -h
send-keys "command -v sensors && watch sensors || exit" Enter

select-pane -t 1

