
split-window -v -c "#{pane_current_path}"

swap-pane -U
resize-pane -y 15
send-keys "watch --color -n 0.5 git --no-pager ll" Enter

split-window -h -c "#{pane_current_path}"
send-keys "watch --color -n 0 git -c color.status=always st" Enter
resize-pane -x 70

select-pane -t 3

