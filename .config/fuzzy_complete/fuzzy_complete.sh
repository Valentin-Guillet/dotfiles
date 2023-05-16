#!/bin/bash

# Overwrite file and directory completion function from /usr/share/bash-completion/bash_completion


# Copy the code of _filedir function to _original_function
if [[ $(type -t _original_filedir) != function ]]
then
    eval "$(type _filedir | tail +2 | sed -e 's/^_filedir/_original_filedir/')"
fi

# Same for _xpec completion
if [[ $(type -t _original_filedir_xspec) != function ]]
then
    eval "$(type _filedir_xspec | tail +2 | sed -e 's/^_filedir_xspec/_original_filedir_xspec/')"
fi


_fuzzy_complete() {
    # Blacklist rm
    local cmd="${COMP_WORDS[0]}"
    [ "$cmd" == "rm" ] && return

    local only_dir=0
    [[ ${1-} == -d ]] && only_dir=1

    local is_cd_cmd=0
    if [ "$cmd" == "cd" ] || [ "$cmd" == "pushd" ] || [ "$cmd" == "pu" ]
    then
        is_cd_cmd=1
    fi

    # If no candidates, call fuzzy completion
    if [ ${#COMPREPLY[@]} == 0 ] || [ $is_cd_cmd == 1 -a ${#COMP_WORDS[@]} -gt 2 ]
    then
        local IFS=$'\n'
        COMPREPLY=( $(/usr/bin/env python -B $HOME/.config/fuzzy_complete/fuzzy_complete.py $only_dir $COMP_CWORD "${COMP_WORDS[@]}") )
        compopt -o filenames
    fi
}

_filedir() {
    _original_filedir "$@"
    _fuzzy_complete "$@"
}


_filedir_xspec() {
    _original_filedir_xspec "$@"
    _fuzzy_complete "$@"
}
