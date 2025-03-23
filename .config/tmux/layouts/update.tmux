
select-pane -t 1
if-shell '[ -x "$(which apt)" ]' 'send-keys "sudo apt update" Enter' 'send-keys "sudo pacman -Syu" Enter'

split-window -v
send-keys "pip_update && exit" Enter

select-pane -t 2
select-pane -t 1

