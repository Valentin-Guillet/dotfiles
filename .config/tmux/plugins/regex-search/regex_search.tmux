#!/usr/bin/env bash

main() {
    local search_files="(((/|~/|\\.|\\.\\.|[[:space:]]|[[:space:]]\\.|[[:space:]]\\.\\.|^\\.\\.)[[:alnum:]_\\.-]+/)|((^|[[:space:]])(/|~/|\\.)))[[:alnum:]_/\\.-]+"
    local search_url="(https?://|git@|git://|ssh://|ftp://|file:///)[[:alnum:]?=%/_.:,;~@!#$&()*+-]*"

    tmux bind-key C-f copy-mode \\\; send-keys -X search-backward "$search_files"
    tmux bind-key C-u copy-mode \\\; send-keys -X search-backward "$search_url"
    tmux bind-key C-g run-shell "$HOME/.config/tmux/plugins/regex-search/git_status_search.sh #{pane_current_path}"

    local shell_line="$(id -un)@$(hostname)"
    tmux bind-key -T copy-mode-vi M-u send-keys 0 \\\; send-keys -X search-backward-text "$shell_line"
    tmux bind-key -T copy-mode-vi M-d send-keys -X search-forward-text "$shell_line"
}

main
