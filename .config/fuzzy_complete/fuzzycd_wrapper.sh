#!/bin/bash

# This displaces the normal bash "cd" builtin command. cd needs to be redefined this way because it's not
# a normal binary, but rather a Bash builtin.

# The "cd" command may have already been redefined by another script (RVM does this, for example):
if [[ $(type -t cd) == function ]] && ! type cd | grep fuzzycd &> /dev/null
then
    # In this case, we define a new "original_cd" function with the same body as the previously defined "cd"
    # function.
    eval "$(type cd | tail +2 | sed 's/^cd/original_cd/')"
else
    # Otherwise, we just define "original_cd" to directly call the builtin.
    eval "original_cd() { builtin cd \"\$@\"; }"
fi

cd() {
    if [ ! -x $HOME/.config/fuzzy_complete/fuzzycd.py ]
    then
        echo "Fuzzycd not found or not executable"
        original_cd "$@"
        return
    fi

    $HOME/.config/fuzzy_complete/fuzzycd.py "$@"

    # fuzzycd communicates to this bash wrapper through a temp file, because it uses STDOUT for other purposes.
    output=$(cat /tmp/fuzzycd.out)
    rm /tmp/fuzzycd.out

    if [ "$output" = "@nomatches" ]; then
        echo "No files match \"$@\""
    elif [ "$output" = "@passthrough" ]; then
        original_cd "$@"
    elif [ "$output" != "@exit" ]; then
        original_cd "$output"
    fi
}
