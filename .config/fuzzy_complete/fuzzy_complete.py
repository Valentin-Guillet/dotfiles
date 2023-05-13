#!/usr/bin/env python

import sys
from pathlib import Path

from fuzzy_lib import debug
from fuzzy_lib import find_matching_dirs


def exist_and_dont_have_subdirs(path_str):
    path = Path(path_str)
    if not (path.exists() and path.is_dir()):
        return False

    try:
        return all(not subpath.is_dir() for subpath in path.iterdir())
    except PermissionError:
        pass
    return False


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


# def count_parts(arg):
#     nb_parts = 0

#     # Each `...` count as a part
#     while arg[nb_parts:].startswith("..."):
#         nb_parts += 1

#     nb_parts += arg.count("/")

#     return nb_parts


def main():
    only_dir = (sys.argv[1] == "1")
    cword = int(sys.argv[2])
    cmd_is_cd = (sys.argv[3] in ("cd", "pushd", "pu"))
    args = [arg.replace("\\ ", " ") for arg in sys.argv[4:]]

    debug("-"*50)
    debug("Args", args)
    debug("Cword", cword)
    debug("Only dir", only_dir)

    # Only apply completion in arguments > 2 for `cd`
    # (i.e. `cd doc exp` -> `cd doc Example/`)
    # Otherwise, only complete CWORD argument
    if not cmd_is_cd:
        args = [args[cword - 1]]

    found_dirs, nb_parts_last_arg = find_matching_dirs(args,
                                                       only_dir=only_dir,
                                                       filter_fn=filter_first_chars)

    # found_dirs = [Path()]
    # allow_by_char = True
    # nb_parts_last_arg = 0
    # nb_parts_prev_arg = 0
    # for i, arg in enumerate(args):
    #     found_dirs = matches_for_path(found_dirs, arg, allow_by_char,
    #                                   include_files=(not only_dir),
    #                                   filter_fn=filter_first_chars)

    #     debug("Arg", arg)
    #     debug("Found dirs", found_dirs)
    #     debug("Allow chars", allow_by_char)

    #     if found_dirs:
    #         nb_part = len(found_dirs[0].parts)
    #         nb_parts_last_arg = nb_part - nb_parts_prev_arg
    #         nb_parts_prev_arg = nb_part

    #     if not (i == 0 and arg in ("/", "~")):
    #         allow_by_char = False

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
        output = "\n".join(map(str, found_dirs))
        if cmd_is_cd:
            output += "\n\u1160"
        print(output)
        return

    # Truncate the path to modify only the last part of the arguments in the case of cd
    # i.e. `cd doc ex` => `found_dirs = ["Documents/example1"]`
    #                  => matches = ["example1"]
    #                  => `cd doc example1` instead of `cd doc Documents/example1`
    matches = [Path(*found_dir.parts[-nb_parts_last_arg:]) for found_dir in found_dirs]

    debug("Matches", matches)

    # if only_dir and exist_and_dont_have_subdirs("/".join(path_patterns)):
    #     return

    # matches = matches_for_path(root, path_patterns,
    #                            include_files=(not only_dir),
    #                            filter_fn=filter_first_chars)
    # debug("Matches", matches)

    matching_path = matches[0]
    debug("Matching path:", matching_path)

    # match_by_char case: replace with the whole path
    # if len(args) == 1 and len(matching_path.parts) > 1:
        # Must remove prefix in the cd case called with split root
        # e.g. `cd / vo` -> `cd /var/opt` instead of `cd / /var/opt`
        # debug("Matching by char")
        # if cmd_is_cd and len(args) > 1:
        #     matching_path = matching_path.relative_to(root)
        # print(str(matching_path))
        # return

    # Last argument is not empty: user is currently inputing a word
    if args[-1]:
        # For cd, if there's only one match, only expand the last part of the input
        if cmd_is_cd:
            matching_path = Path(*matching_path.parts[-nb_parts_last_arg:])
            debug("Nb parts", nb_parts_last_arg)
            debug("Truncated", matching_path)

        print(str(matching_path))
        return

    # The last argument is empty: acts as ls and complete with all
    # existing subdirs
    try:
        subdirs = matching_path.iterdir()
        ans = [str(p) for p in subdirs if p.is_dir()]
    except (PermissionError, StopIteration):
        return

    if not ans:
        return

    if len(ans) == 1:
        print(Path(ans[0]).name)
        return

    ans.sort()
    # Cf comment above
    print("\n".join(ans) + "\n\u1160")

if __name__ == "__main__":
    main()

