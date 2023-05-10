#!/usr/bin/env python

"""
Take a path argument and generates a list of possible completions using fuzzy matching.
For example:
  `p` matches `places/` and `suspects/`
  `p/h` matches `places/home/` and `suspects/harry/`

If there is more than one match, an interactive menu will be shown via STDOUT to select the intended match.
This script is intended to be invoked from fuzzycd_wrapper.sh, which collects the output of this script
and forwards the chosen path to the original cd command.
This script communicates with its parent fuzzycd_wrapper.sh through the file "/tmp/fuzzycd.out";
this is required because this script uses STDOUT to show the interactive menu when necessary.

Largely inspired by FuzzyCD from PhilC (https://github.com/philc/fuzzycd)
"""

import os
from pathlib import Path


def debug(*args):
    with (Path(os.environ["HOME"]) / "out.log").open("a") as file:
        file.write(" ".join(map(str, args)) + "\n")


def split_root(args):
    root = Path()
    path_patterns = []
    for arg in args:
        path_patterns += list(Path(arg).parts)

    if not path_patterns:
        return root, path_patterns

    home_parts = Path.home().parts
    if path_patterns[0] in ("/", "//"):
        root = Path("/")
        del path_patterns[0]

    elif path_patterns[0].startswith("~"):
        root = Path.home()
        if len(path_patterns[0]) == 1:
            path_patterns = path_patterns[1:]
        else:
            path_patterns[0] = path_patterns[0][1:]

    elif path_patterns[:len(home_parts)] == home_parts:
        root = Path.home()
        path_patterns = path_patterns[len(home_parts):]

    return root, path_patterns


def get_subdirs(directory):
    """ Return the list of all subdirs of a given directory that are readable"""
    if not os.access(directory, os.R_OK):
        return []

    return [subdir for subdir in directory.iterdir()
            if os.access(subdir, os.R_OK) and subdir.is_dir()]


def get_files(directory):
    """ Return the list of all files of a given directory"""
    if not os.access(directory, os.R_OK):
        return []

    return [file for file in directory.iterdir()
            if os.access(file, os.R_OK) and file.is_file()]


def name_match(pattern, name):
    """ Check if a name matches a pattern, with potentially missing characters.
    For instance, `dcm` match `documents` and `decimal`, but not `dmc` nor 'declaration'.
    If the pattern doesn't have any uppercase, the check is case insensitive.
    """
    if pattern.islower():
        name = name.lower()

    debug(f"    Name match: {pattern} in {name}")

    prev_index = 0
    for char in pattern:
        if char not in name[prev_index:]:
            return False

        index = name.index(char, prev_index)
        if index < prev_index:
            return False

        prev_index = index + 1

    return True


def filter_matches(pattern, found_dirs):
    """ Apply an arbitrary filter on directories matching a pattern.
    1. If the pattern does not start with a dot, remove hidden directories
       (except if there is no non-hidden matching directories)
    2. If several directories match, only return the ones with the earliest
       occurence of the pattern's first character
    """
    if not found_dirs:
        return []

    # Avoid hidden dirs
    if not pattern.startswith("."):
        not_hidden_dirs = [d for d in found_dirs if not d.name.startswith(".")]
        if not_hidden_dirs:
            found_dirs = not_hidden_dirs

    min_index = 1000
    closest_dirs = []
    for directory in found_dirs:
        name = directory.name
        if pattern.islower():
            name = name.lower()
        ind = name.index(pattern[0])
        if ind < min_index:
            min_index = ind
            closest_dirs = [directory]
        elif ind == min_index:
            closest_dirs.append(directory)

    return closest_dirs


def matches_by_chars(root, path_patterns, *, include_files=False):
    """ Return an array of all matches for a given tuple of single letter path parts.
    """
    found_dirs = [root]

    # Expand `...` and more in `../..`
    while path_patterns[:2] == (".", "."):
        found_dirs = [d.absolute().parent for d in found_dirs]
        path_patterns = path_patterns[1:]

    # Remove leading ".", either intentional of aftermath of "..." expansion
    if path_patterns[0] == ".":
        path_patterns = path_patterns[1:]

    for i, char in enumerate(path_patterns):
        dir_pattern_index = {}

        for directory in found_dirs:
            paths = get_subdirs(directory)
            if include_files and i == len(path_patterns) - 1:
                paths.extend(get_files(directory))

            for path in paths:
                name = path.name.lower() if char.islower() else path.name
                if char in name:
                    dir_pattern_index.setdefault(name.index(char), []).append(path)

        if not dir_pattern_index:
            return []

        found_dirs = dir_pattern_index[min(dir_pattern_index)]

    return found_dirs


def matches_for_path(root, path_patterns, *, include_files=False, filter_fn=None):
    """ Return an array of all matches for a given path, possibly filtered by a given function
    (by default, `filter_match()`).
    Each part of the path is a globed (fuzzy) match. For example:
      `p` matches `places/` and `suspects/`
      `p/h` matches `places/home` and `suspects/harry`
    """
    # path_patterns = []
    # for path in path_list:
    #     path_patterns += list(Path(path).parts)

    # home_parts = Path.home().parts

    # # If args start with ~, expand user
    # if path_patterns[0].startswith("~"):
    #     new_path_patterns = home_parts
    #     if len(path_patterns[0]) > 1:
    #         new_path_patterns += (path_patterns[0][1:], )
    #     new_path_patterns += path_patterns[1:]
    #     path_patterns = new_path_pattern

    # # If start with home, add it to root
    # if path_patterns[:len(home_parts)] == home_parts:
    #     root = Path.home()
    #     path_patterns = path_patterns[len(home_parts):]

    # if not path_patterns:
    #     return []

    # # If start with /, add it to root
    # if path_patterns[0] in ("/", "//"):
    #     root = Path("/")
    #     path_patterns = path_patterns[1:]

    # path_patterns = list(path_patterns)

    debug(f"  In matches_for_path: {root}, {path_patterns}")

    # Expand `...` and more in `../..`
    index = 0
    while index < len(path_patterns):
        pattern = path_patterns[index]
        if not (len(pattern) > 2 and pattern == "." * len(pattern)):
            index += 1
            continue

        path_patterns[index] = ".."
        for _ in range(len(pattern) - 2):
            path_patterns.insert(index + 1, "..")

        index += len(pattern) - 2 + 1

    found_dirs = [root]
    found_files = []
    for i, pattern in enumerate(path_patterns):
        if pattern == "..":
            found_dirs = [d.absolute().parent for d in found_dirs]
            continue

        new_found_dirs = []
        for directory in found_dirs:
            new_found_dirs.extend([subdir for subdir in get_subdirs(directory)
                                   if name_match(pattern, subdir.name)])

        # When considering the last pattern, add files if include_files is True
        if include_files and i == len(path_patterns) - 1:
            for directory in found_dirs:
                found_files = [file for file in get_files(directory)
                               if name_match(pattern, file.name)]

        found_dirs = new_found_dirs
        if filter_fn is None:
            filter_fn = filter_matches
        found_dirs = filter_fn(pattern, found_dirs)

        # If no matching dir has been found for the first pattern and path
        # is only composed of one part, treat each character as a pattern
        if i == 0 and not found_dirs:
            found_dirs = matches_by_chars(root, tuple(pattern), include_files=include_files)

    if include_files:
        return [str(path) for path in found_dirs + found_files]

    return [str(directory) for directory in found_dirs]

