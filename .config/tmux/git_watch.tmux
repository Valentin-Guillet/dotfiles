split-window -v -c "#{pane_current_path}"

swap-pane -U
resize-pane -y 15
send-keys "git ll" Enter

split-window -h -c "#{pane_current_path}"
send-keys "watch --color -n 0 git -c color.status=always st" Enter

select-pane -t 3

