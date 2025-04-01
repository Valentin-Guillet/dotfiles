#!/bin/bash

# Overwrite file and directory completion function from /usr/share/bash-completion/bash_completion


# _filedir and _filedir_xspec are used in bash-completion < 2.12
# _comp_compgen_filedir and _comp_compgen_filedir_xspec are used in bash-completion >= 2.12
for function in _filedir _filedir_xspec _comp_compgen_filedir _comp_compgen_filedir_xspec; do
    [[ $(type -t $function) != function ]] && continue

    # Check if script has already been sourced
    if [[ $(type -t _original$function) != function ]]; then

        # Copy the code of $function to _original$function to be able to call it
        eval "$(type $function | tail +2 | sed -e "s/^$function/_original$function/")"

        # Call fuzzy complete after the call to the original function
        eval "$function() {
            _original$function \"\$@\"
            _fuzzy_complete \"\$@\"
        }"
    fi
done


# In bash-completion<2.12, the default completion function `_minimal` used to call _filedir
# by default. However, in commit b9c56ebf00d1e4c4f85d87b40026497dbb97d6f6 this got modified
# to use the default bash completion as it allows for wildcards completion (cf. issue
# https://github.com/scop/bash-completion/issues/444)
# In our case, we don't care about default bash completion so we overwrite this minimal
# completion function to call _comp_compgen_filedir again, which allows for calling our fuzzy
# complete function again by default
if [[ $(type -t _comp_complete_minimal) == function ]]; then
    _comp_complete_minimal() {
        local cur prev words cword comp_args
        _comp_initialize -- "$@" || return
        _comp_compgen_filedir
    }
fi


_fuzzy_complete() {
    # Blacklist rm
    local cmd="${COMP_WORDS[0]}"
    [ "$cmd" == "rm" ] && return

    # Don't complete on empty commandline
    [ -z "$cmd" ] && return

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
        COMPREPLY=( $(/usr/bin/env python3 -B $HOME/.config/fuzzy_complete/fuzzy_complete.py $only_dir $COMP_CWORD "${COMP_WORDS[@]}") )
        compopt -o filenames
    fi
}
