#!/usr/bin/env python3

import sys
from pathlib import Path

from fuzzy_lib import find_matching_dirs


def filter_first_chars(pattern, found_dirs):
    if not found_dirs:
        return []

    best_matches = []
    max_match = 0
    for directory in found_dirs:
        name = directory.name
        if pattern.islower():
            name = name.lower()
        i = 0
        while i < len(name) and i < len(pattern) and name[i] == pattern[i]:
            i += 1
        if i > max_match:
            max_match = i
            best_matches = [directory]
        elif i == max_match:
            best_matches.append(directory)

    return best_matches


def main():
    only_dir = (sys.argv[1] == "1")
    cword = int(sys.argv[2])
    cmd_is_cd = (sys.argv[3] in ("cd", "pushd", "pu"))
    args = [arg.replace("\\ ", " ") for arg in sys.argv[4:]]

    # Only apply completion in arguments > 2 for `cd`
    # (i.e. `cd doc exp` -> `cd doc Example/`)
    # Otherwise, only complete CWORD argument
    if not cmd_is_cd:
        args = [args[cword - 1]]

    found_dirs, nb_parts_last_arg = find_matching_dirs(args,
                                                       only_dir=only_dir,
                                                       filter_fn=filter_first_chars)

    if not found_dirs:
        return

    # Normally readline wants to complete with the longest common parts
    # on all possible completions, e.g. if `matches[0]` == "Documents/",
    # `ans` can be ["Documents/Pictures", "Documents/Notes"]
    # and readline will change `cd doc ` by `cd doc Documents/`.
    # To avoid that, we add an invisible character at the end of the
    # answers so that the longest common part becomes empty, and readline
    # can't modify the user's input
    # This character is a special unicode whitespace with a high code so
    # that it appears after all other options and don't leave an empty box
    if len(found_dirs) != 1:
        print("\n".join(map(str, found_dirs)) + "\n\u1160")
        return

    matching_path = found_dirs[0]

    # Truncate the path to modify only the last part of the arguments in the case of cd
    # i.e. `cd doc ex` => `found_dirs = ["Documents/example1"]`
    #                  => `matches = ["example1"]`
    #                  => `cd doc example1` (instead of `cd doc Documents/example1`)
    output = str(Path(*matching_path.parts[-nb_parts_last_arg:]))

    # Add slash when there's only one possibility to complete cd
    # e.g. `cd doc exmp` -> `cd doc examples/`
    if matching_path.is_dir() and cmd_is_cd and not output.endswith("/"):
        output += "/"

    print(output)


if __name__ == "__main__":
    main()

