#!/usr/bin/env python

import sys
from pathlib import Path

from fuzzy_lib import matches_for_path, split_root
from fuzzy_lib import debug


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


def main():
    only_dir = (sys.argv[1] == "1")
    args = [arg.replace("\\ ", " ") for arg in sys.argv[3:]]

    # Only apply completion in arguments > 2 for `cd`
    # (i.e. `cd doc exp` -> `cd doc Example/`)
    cmd = sys.argv[2]
    if cmd in ("cd", "pushd", "pu"):
        root, path_patterns = split_root(args)
    else:
        root = Path()
        path_patterns = list(Path(args[-1]).parts)

    debug("-"*50)
    debug("Args", args)
    debug("Root", root)
    debug("Path list", path_patterns)

    if cmd not in ("cd", "pushd", "pu"):
        path_patterns = path_patterns[-1]

    if only_dir and exist_and_dont_have_subdirs("/".join(path_patterns)):
        return

    matches = matches_for_path(root, path_patterns, filter_fn=filter_first_chars)
    debug("Matches", matches)
    if not matches:
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
    if len(matches) != 1:
        print("\n".join(matches) + "\n\u1160")
        return

    matching_path = Path(matches[0])

    debug("Matching path:", matching_path)

    # match_by_char case: replace with the whole path
    if len(path_patterns) == 1 and len(matching_path.parts) > 1:
        # Must remove prefix in the cd case called with split root
        # e.g. `cd / vo` -> `cd /var/opt` instead of `cd / /var/opt`
        if len(args) > 1:
            matching_path = matching_path.relative_to(root)
        print(str(matching_path))
        return

    # Last argument is not empty: user is currently inputing a word
    # So if there's only one match, complete just this last part
    if path_patterns[-1]:
        # debug(1)
        nb_parts = path_patterns[-1].count("/", 1)
        truncated_path = Path(*matching_path.parts[-nb_parts-1:])
        # debug("Truncated", truncated_path)
        print(str(truncated_path))
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
        # debug(2)
        print(Path(ans[0]).name)
        return

    # debug(3)
    ans.sort()
    # Cf comment above
    print("\n".join(ans) + "\n\u1160")

if __name__ == "__main__":
    main()
