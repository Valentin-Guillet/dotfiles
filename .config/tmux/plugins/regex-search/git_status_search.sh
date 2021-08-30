#!/usr/bin/env bash

PANE_CURRENT_PATH="$1"

git_status_files() {
	git -C "$PANE_CURRENT_PATH" status -s
}

formatted_git_status() {
	local raw_gist_status="$(git_status_files)"
	echo "$raw_gist_status" | cut -c 4- | sed 's/ -> /\|/'
}

exit_if_no_results() {
	local results="$1"
	if [ -z "$results" ]; then
		tmux display-message "No results!"
		exit 0
	fi
}

concatenate_files() {
	local git_status_files="$(formatted_git_status)"
	exit_if_no_results "$git_status_files"

	local result=""
	# Undefined until later within a while loop.
	local file_separator
	while read -r line; do
		result="${result}${file_separator}${line}"
		file_separator="|"
	done <<< "$git_status_files"
	echo "$result"
}

# Creates one, big regex out of git status files.
# Example:
# `git status` shows files `foo.txt` and `bar.txt`
# output regex will be:
# `(foo.txt|bar.txt)
git_status_files_regex() {
	local concatenated_files="$(concatenate_files)"
	local regex_result="(${concatenated_files})"
	echo "$regex_result"
}

main() {
	local search_regex="$(git_status_files_regex)"
    tmux copy-mode \; send-keys -X search-backward "$search_regex"
}
main
