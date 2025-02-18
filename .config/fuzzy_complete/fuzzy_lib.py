#!/usr/bin/env python3

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


def get_subdirs(directory):
    """ Return the sorted list of all subdirs of a given directory that are readable"""
    if not os.access(directory, os.R_OK):
        return []

    return sorted([subdir for subdir in directory.iterdir()
                   if os.access(subdir, os.R_OK) and subdir.is_dir()])


def get_files(directory):
    """ Return the sorted list of all files of a given directory that are readable"""
    if not os.access(directory, os.R_OK):
        return []

    return sorted([file for file in directory.iterdir()
                   if os.access(file, os.R_OK) and file.is_file()])


def get_subdirs_and_files(directories, include_files):
    found_dirs = []
    found_files = []
    for base_dir in directories:
        if not base_dir.is_dir():
            continue

        found_dirs.extend(get_subdirs(base_dir))
        if include_files:
            found_files.extend(get_files(base_dir))

    return found_dirs + found_files


def turn_into_relpath(paths, base_path):
    """ Transform absolute path list `paths` in relative paths from `base_path`.

    The relative paths are forced to go through the common path to avoid the following case:
    turn_into_relpath(["/tmp/ex_1", "/tmp/ex_2", "/tmp/ex_3"], "/tmp/ex_2") = ["../ex_1", "./", "../ex_3"]
    (instead of ["../ex_1", "../ex_2", "../ex_3"])
    """
    if not paths:
        return paths

    paths = [path.absolute() for path in paths]
    common_path = Path(os.path.commonpath([*paths, base_path.absolute()]))

    if common_path == Path("/"):
        return paths

    relpaths = []
    for path in paths:
        base_to_common = Path(os.path.relpath(common_path, base_path))
        common_to_path = Path(os.path.relpath(path, common_path))
        relpaths.append(base_to_common / common_to_path)

    return relpaths


def name_match(pattern, name):
    """ Check if a name matches a pattern, with potentially missing characters.
    For instance, `dcm` match `documents` and `decimal`, but not `dmc` nor 'declaration'.
    If the pattern doesn't have any uppercase, the check is case insensitive.
    """
    if pattern.islower():
        name = name.lower()

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


def matches_by_chars(base_dirs, path_pattern, *, include_files=False):
    """ Return an array of all matches from a list of base directories for a given pattern
    of single letter path parts.
    """
    found_dirs = base_dirs
    char_patterns = tuple(path_pattern)

    # Leading dots act as "../"
    if path_pattern.startswith(".."):
        i = 0
        while path_pattern[i] == ".":
            i += 1
        for _ in range(i - 1):
            found_dirs = [d.absolute().parent for d in found_dirs]
        char_patterns = char_patterns[i:]

    is_hidden = False
    for i, char in enumerate(char_patterns):
        # A "." makes the following char look at hidden files only
        if char == ".":
            is_hidden = True
            continue

        dir_pattern_index = {}

        for directory in found_dirs:
            paths = get_subdirs(directory)
            if include_files and i == len(char_patterns) - 1:
                paths.extend(get_files(directory))

            if is_hidden:
                paths = [path for path in paths if path.name.startswith(".")]

            for path in paths:
                name = path.name.lower() if char.islower() else path.name
                if char in name:
                    dir_pattern_index.setdefault(name.index(char), []).append(path)

        if not dir_pattern_index:
            return []

        is_hidden = False
        found_dirs = dir_pattern_index[min(dir_pattern_index)]

    return found_dirs


def matches_for_path(base_dirs, path_arg, allow_by_char, expand_sep, *,
                     is_last=False, include_files=False, filter_fn=filter_matches):
    """ Return an array of all matches from a list of base directories for a given path pattern,
    possibly filtered by a given function (by default, `filter_matches()`).
    Each part of the path is a globed (fuzzy) match. For example:
      `p` matches `places/` and `suspects/`
      `p/h` matches `places/home` and `suspects/harry`
    """
    if not base_dirs:
        return []

    path_patterns = list(Path(path_arg).parts)

    # This takes care of the case where path_arg is (a variation of) `./`
    if not path_patterns and not is_last:
        return base_dirs

    # If arg is empty, complete with subdirs and files as usual
    # i.e. `ls doc [TAB]` -> `[Documents/example_1, Documents/example_2]`
    # Happens when path_arg is `./` in last or when path_arg == ""
    if not path_arg or not path_patterns:
        return get_subdirs_and_files(base_dirs, include_files)

    if path_patterns[0] == "/":
        base_dirs = [Path("/")]
        path_patterns = path_patterns[1:]

    elif path_patterns[0].startswith("~"):
        base_dirs = [Path.home()]
        if path_patterns[0] == "~":
            path_patterns = path_patterns[1:]
        else:
            path_patterns[0] = path_patterns[0][1:]

    is_first_word_path = True
    return_relative_paths = False
    found_dirs = base_dirs
    found_files = []
    for i, pattern in enumerate(path_patterns):
        if i == 0 and pattern == "/":
            found_dirs = [Path("/")]
            continue

        if i == 0 and pattern == "~":
            found_dirs = [Path.home()]
            continue

        if pattern == "." * len(pattern):
            return_relative_paths = True
            for _ in range(len(pattern) - 1):
                found_dirs = [d.absolute().parent for d in found_dirs]
            continue

        new_found_dirs = []
        for directory in found_dirs:
            new_found_dirs.extend([subdir for subdir in get_subdirs(directory)
                                   if name_match(pattern, subdir.name)])

        # When considering the last pattern, add files if include_files is True
        if include_files and i == len(path_patterns) - 1:
            for directory in found_dirs:
                found_files.extend([file for file in get_files(directory)
                                    if name_match(pattern, file.name)])
            found_files = filter_fn(pattern, found_files)

        found_dirs = filter_fn(pattern, new_found_dirs)

        # If no matching dir has been found for the first pattern and path
        # is only composed of one part, treat each character as a pattern
        if allow_by_char and is_first_word_path and not found_dirs:
            if pattern.startswith(".."):
                return_relative_paths = True
            found_dirs = matches_by_chars(base_dirs, pattern, include_files=include_files)

        is_first_word_path = False

    # Argument ends with a slash, complete with subdirs and files
    if expand_sep and path_arg.endswith("/"):
        path_output = get_subdirs_and_files(found_dirs, include_files)
    else:
        path_output = found_dirs + found_files

    if is_last and return_relative_paths:
        return turn_into_relpath(path_output, base_dirs[0])

    return path_output


def find_matching_dirs(args, *, only_dir, filter_fn=filter_matches, expand_last_sep=True):
    found_dirs = [Path()]
    allow_by_char = True
    nb_parts_last_arg = 0
    nb_parts_prev_arg = 0

    for i, arg in enumerate(args):
        is_last = (i == len(args) - 1)

        found_dirs = matches_for_path(
                found_dirs, arg, allow_by_char,
                expand_sep=(expand_last_sep and is_last),
                is_last=is_last,
                include_files=(not only_dir),
                filter_fn=filter_fn,
        )

        if found_dirs:
            nb_part = len(found_dirs[0].parts)
            nb_parts_last_arg = nb_part - nb_parts_prev_arg
            nb_parts_prev_arg = nb_part

        if not (i == 0 and arg in ("/", "~")):
            allow_by_char = False

    return found_dirs, max(nb_parts_last_arg, 0)

