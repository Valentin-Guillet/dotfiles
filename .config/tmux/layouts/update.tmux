
select-pane -t 1
send-keys "sudo apt update" Enter

split-window -v
send-keys "pip_update && exit" Enter

select-pane -t 2
select-pane -t 1

