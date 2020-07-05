
run-shell "tmux list-sessions | cut -d : -f 1 > ~/.config/tmux/list_sessions &&\
           head -n 1 ~/.config/tmux/list_sessions >> ~/.config/tmux/list_sessions &&\
           sed -ni '/#S/ {n;p;q}' ~/.config/tmux/list_sessions &&\
           echo \"move-window -t $(cat ~/.config/tmux/list_sessions):\" > ~/.config/tmux/list_sessions"

source-file ~/.config/tmux/list_sessions
switch-client -n

run-shell "rm ~/.config/tmux/list_sessions"
