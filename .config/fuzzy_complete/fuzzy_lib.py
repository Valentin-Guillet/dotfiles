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


def get_relative_to_cwd(path):
    i = 0
    for cwd_part, path_part in zip(Path.cwd().parts, path.parts, strict=False):
        if cwd_part != path_part:
            break
        i += 1

    # No parts in common to the root: return absolute path
    if i <= 1:
        return path

    nb_prev = len(Path.cwd().parts) - i
    nb_next = len(path.parts) - i
    # debug(f"      Rel to: path {path}, cwd {Path.cwd()}")
    # debug(f"      i {i}, nb_prev {nb_prev}, nb_next {nb_next}")

    rel_path = tuple(".." for _ in range(nb_prev))
    if nb_next:
        rel_path += path.parts[-nb_next:]

    # debug(f"      => {rel_path}")
    return Path(*rel_path)


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
    """ Return an array of all matches for a given tuple of single letter path parts.
    """
    found_dirs = base_dirs

    return_relative_paths = False
    i = 0
    while path_pattern[i] == ".":
        return_relative_paths = True
        i += 1
    for _ in range(i - 1):
        found_dirs = [d.absolute().parent for d in found_dirs]
    char_patterns = tuple(path_pattern[i:])

    # debug(f"   By chars: base_dirs {base_dirs}, path pattern {path_pattern}, char patterns {char_patterns}")

    for i, char in enumerate(char_patterns):
        dir_pattern_index = {}

        for directory in found_dirs:
            paths = get_subdirs(directory)
            if include_files and i == len(char_patterns) - 1:
                paths.extend(get_files(directory))

            for path in paths:
                name = path.name.lower() if char.islower() else path.name
                if char in name:
                    dir_pattern_index.setdefault(name.index(char), []).append(path)

        if not dir_pattern_index:
            return []

        found_dirs = dir_pattern_index[min(dir_pattern_index)]

    if return_relative_paths:
        found_dirs = [get_relative_to_cwd(found_dir) for found_dir in found_dirs]

    return found_dirs


def matches_for_path(base_dirs, path_arg, allow_by_char, *,
                     include_files=False, filter_fn=filter_matches):
    """ Return an array of all matches for a given path, possibly filtered by a given function
    (by default, `filter_matches()`).
    Each part of the path is a globed (fuzzy) match. For example:
      `p` matches `places/` and `suspects/`
      `p/h` matches `places/home` and `suspects/harry`
    """
    if not base_dirs:
        return []

    if not path_arg:
        found_dirs = []
        for base_dir in base_dirs:
            found_dirs.extend(get_subdirs(base_dir))
        found_dirs.sort()
        return found_dirs

    debug("  Path_arg is of length", len(path_arg))

    path_patterns = list(Path(path_arg).parts)
    debug(f"  In matches_for_path: {base_dirs}, {path_patterns}")

    if not path_arg or not path_patterns:
        return base_dirs

    if path_patterns[0] == "/":
        base_dirs = [Path("/")]
        path_patterns = path_patterns[1:]

    elif path_patterns[0].startswith("~"):
        base_dirs = [Path.home()]
        if path_patterns[0] == "~":
            path_patterns = path_patterns[1:]
        else:
            path_patterns[0] = path_patterns[0][1:]

    # # Expand `...` and more in `../..`
    # index = 0
    # while index < len(path_patterns):
    #     pattern = path_patterns[index]
    #     if not (len(pattern) > 2 and pattern == "." * len(pattern)):
    #         index += 1
    #         continue

    #     path_patterns[index] = ".."
    #     for _ in range(len(pattern) - 2):
    #         path_patterns.insert(index + 1, "..")

    #     index += len(pattern) - 2 + 1

    #     return_relative_paths = True

    # debug(f"  After ... expansion: {path_patterns}")

    is_first_word_path = True
    return_relative_paths = False
    found_dirs = base_dirs
    found_files = []
    for i, pattern in enumerate(path_patterns):
        debug("  Start found dirs", found_dirs)

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

        # if pattern == "..":
        #     found_dirs = [d.absolute().parent for d in found_dirs]
        #     continue

        new_found_dirs = []
        for directory in found_dirs:
            new_found_dirs.extend([subdir for subdir in get_subdirs(directory)
                                   if name_match(pattern, subdir.name)])

        # When considering the last pattern, add files if include_files is True
        if include_files and i == len(path_patterns) - 1:
            for directory in found_dirs:
                found_files.extend([file for file in get_files(directory)
                                    if name_match(pattern, file.name)])
                debug("Found files:", found_files)
            found_files = filter_fn(pattern, found_files)

        found_dirs = filter_fn(pattern, new_found_dirs)

        # If no matching dir has been found for the first pattern and path
        # is only composed of one part, treat each character as a pattern
        if allow_by_char and is_first_word_path and not found_dirs:
            found_dirs = matches_by_chars(base_dirs, pattern, include_files=include_files)

        debug("  -> Found dirs", found_dirs)
        is_first_word_path = False

    if return_relative_paths:
        found_dirs = [get_relative_to_cwd(found_dir) for found_dir in found_dirs]
        found_files = [get_relative_to_cwd(found_file) for found_file in found_files]

    if include_files:
        return found_dirs + found_files

    return found_dirs


def find_matching_dirs(args, *, only_dir, filter_fn=filter_matches):
    found_dirs = [Path()]
    allow_by_char = True
    nb_parts_last_arg = 0
    nb_parts_prev_arg = 0

    # If last argument ends with a "/", add an empty pattern to get all subdirs
    if args[-1].endswith("/"):
        args.append("")

    for i, arg in enumerate(args):
        found_dirs = matches_for_path(found_dirs, arg, allow_by_char,
                                      include_files=(not only_dir),
                                      filter_fn=filter_fn)

        debug("Arg", arg)
        debug("Found dirs", found_dirs)
        debug("Allow chars", allow_by_char)

        if found_dirs:
            nb_part = len(found_dirs[0].parts)
            nb_parts_last_arg = nb_part - nb_parts_prev_arg
            nb_parts_prev_arg = nb_part

        if not (i == 0 and arg in ("/", "~")):
            allow_by_char = False

    return found_dirs, nb_parts_last_arg

