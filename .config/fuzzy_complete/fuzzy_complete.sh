#!/bin/bash

# Overwrite file and directory completion function from /usr/share/bash-completion/bash_completion


# Copy the code of _filedir function to _original_function
if [[ $(type -t _original_filedir) != function ]]
then
    eval "$(type _filedir | tail +2 | sed -e 's/^_filedir/_original_filedir/')"
fi

_filedir() {
    _original_filedir "$@"

    # Blacklist rm
    [ ${COMP_WORDS[0]} == "rm" ] && return

    local only_dir=0
    [[ ${1-} == -d ]] && only_dir=1

    # If no candidates, call fuzzy completion
    if [ ${#COMPREPLY[@]} == 0 ] || [ $only_dir == 1 -a ${#COMP_WORDS[@]} -gt 2 ]
    then
        COMPREPLY=( $(/usr/bin/env python -B $HOME/.config/fuzzy_complete/fuzzy_complete.py $only_dir "${COMP_WORDS[@]}") )
        compopt -o filenames
    fi
}
