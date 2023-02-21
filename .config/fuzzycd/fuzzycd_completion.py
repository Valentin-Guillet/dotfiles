#!/usr/bin/env python

import sys
from pathlib import Path

from fuzzycd import matches_for_path


def exist_and_dont_have_subdirs(path_str):
    path = Path(path_str)
    if not (path.exists() and path.is_dir()):
        return False

    try:
        return all([not subpath.is_dir() for subpath in path.iterdir()])
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
    args = [arg.replace('\\ ', ' ') for arg in sys.argv[2:]]

    if exist_and_dont_have_subdirs("/".join(args)):
        return

    matches = matches_for_path(args, filter_fn=filter_first_chars)
    if not matches:
        return

    # Normally readline wants to complete with the longest common parts
    # on all possible completions, e.g. if `matches[0]` == "Documents/",
    # `ans` can be ["Documents/Pictures", "Documents/Notes"]
    # and readline will change `cd doc ` by `cd doc Documents/`.
    # To avoid that, we add a space at the end of the answers so that the
    # the longest common part becomes empty, and readline can't modify
    # the user's input
    # This space character is a special unicode whitespace with a high code so
    # that it appears after all other options and don't leave an empty box
    if len(matches) != 1:
        print("\n".join(matches) + "\n ")   # noqa: RUF001
        return

    matching_path = Path(matches[0])

    # match_by_char case: replace with the whole path
    if (len(args) == 1 or args[0] == "/") and len(matching_path.parts) > 1:
        print(str(matching_path))
        return

    # Last argument is not empty: user is currently inputing a word
    # So if there's only one match, complete just this last part
    if args[-1]:
        nb_parts = args[-1].count("/", 1)
        truncated_path = Path(*matching_path.parts[-nb_parts-1:])
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
        print(Path(ans[0]).name)
        return

    ans.sort()
    # Cf comment above
    print("\n".join(ans) + "\n ")   # noqa: RUF001

if __name__ == "__main__":
    main()
