
select-pane -t 1
send-keys "sudo apt update" Enter

split-window -v
send-keys "conda update --all && exit" Enter

split-window -h
send-keys "pip_update && exit" Enter

select-pane -t 2
select-pane -t 1

