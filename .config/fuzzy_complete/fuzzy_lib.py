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


def get_subpaths(directories: list[Path], *, include_files: bool) -> list[Path]:
    found_paths = []
    for base_dir in directories:
        if not base_dir.is_dir() or not os.access(base_dir, os.R_OK):
            continue

        dirs, files = [], []
        for path in base_dir.iterdir():
            if not os.access(path, os.R_OK):
                continue
            if path.is_dir():
                dirs.append(path)
            elif include_files and path.is_file():
                files.append(path)

        found_paths.extend(sorted(dirs) + sorted(files))

    return found_paths


def turn_into_relpath(paths: list[Path], base_path: Path) -> list[Path]:
    """Transform absolute path list `paths` in relative paths from `base_path`.

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


def name_match(pattern: str, name: str) -> bool:
    """Check if a name matches a pattern, with potentially missing characters.
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


def filter_matches(pattern: str, found_dirs: list[Path]) -> list[Path]:
    """Apply an arbitrary filter on directories matching a pattern.
    1. If the pattern does not start with a dot, remove hidden directories
       (except if there is no non-hidden matching directories)
    2. If several directories match, only keep those who contains the exact pattern
    3. From these directories, return the ones with the earliest
       occurence of the pattern's first character
    """
    if not found_dirs:
        return []

    # Avoid hidden dirs
    if not pattern.startswith("."):
        not_hidden_dirs = [d for d in found_dirs if not d.name.startswith(".")]
        if not_hidden_dirs:
            found_dirs = not_hidden_dirs

    ignore_case = pattern.islower()
    min_index = 1000
    found_exact_match = False
    closest_dirs = []
    for directory in found_dirs:
        name = directory.name.lower() if ignore_case else directory.name
        if found_exact_match and pattern not in name:
            continue

        if pattern in name and not found_exact_match:
            found_exact_match = True
            min_index = 1000

        ind = name.index(pattern[0])
        if ind < min_index:
            min_index = ind
            closest_dirs = [directory]
        elif ind == min_index:
            closest_dirs.append(directory)

    return closest_dirs


def matches_by_chars(
    base_dirs: list[Path],
    path_pattern: str,
    *,
    include_files: bool = False,
) -> list[Path]:
    """Return an array of all matches from a list of base directories for a given pattern
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

        incl = include_files and i == len(char_patterns) - 1
        found_paths = get_subpaths(found_dirs, include_files=incl)
        if is_hidden:
            found_paths = [path for path in found_paths if path.name.startswith(".")]

        # Find all paths that have "char" at the lowest index
        first_char_index = 10000
        first_char_paths = []
        for path in found_paths:
            name = path.name.lower() if char.islower() else path.name
            char_index = name.find(char)
            # Path has "char" at lower index
            if char_index != -1 and char_index < first_char_index:
                first_char_index = char_index
                first_char_paths = [path]

            # Path has "char" at same index
            elif char_index == first_char_index:
                first_char_paths.append(path)

        is_hidden = False
        found_dirs = first_char_paths

    return found_dirs


def matches_for_path(
    base_dirs: list[Path],
    path_arg: str,
    *,
    allow_by_char: bool,
    expand_sep: bool,
    is_last: bool = False,
    include_files: bool = False,
) -> list[Path]:
    """Return an array of all matches from a list of base directories for a given path pattern,
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
        return get_subpaths(base_dirs, include_files=include_files)

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
    for i, pattern in enumerate(path_patterns):
        if pattern == "." * len(pattern):
            return_relative_paths = True
            for _ in range(len(pattern) - 1):
                found_dirs = [d.absolute().parent for d in found_dirs]
            continue

        # Include files on last pattern
        incl = include_files and i == len(path_patterns) - 1
        new_found_dirs = [
            path
            for path in get_subpaths(found_dirs, include_files=incl)
            if name_match(pattern, path.name)
        ]
        found_dirs = filter_matches(pattern, new_found_dirs)

        # If no matching dir has been found for the first pattern and path
        # is only composed of one part, treat each character as a pattern
        if allow_by_char and is_first_word_path and not found_dirs:
            if pattern.startswith(".."):
                return_relative_paths = True

            # Only include files if the char search is the last part of the pattern
            incl = include_files and i == len(path_patterns) - 1
            found_dirs = matches_by_chars(base_dirs, pattern, include_files=incl)

        is_first_word_path = False

    # Argument ends with a slash, complete with subdirs and files
    if expand_sep and path_arg.endswith("/"):
        path_output = get_subpaths(found_dirs, include_files=include_files)
    else:
        path_output = found_dirs

    if is_last and return_relative_paths:
        return turn_into_relpath(path_output, base_dirs[0])

    return path_output


def find_matching_dirs(
    args: list[str],
    *,
    only_dir: bool,
    expand_last_sep: bool = True,
) -> tuple[list[Path], int]:
    found_dirs = [Path()]
    allow_by_char = True
    nb_parts_last_arg = 0
    nb_parts_prev_arg = 0

    for i, arg in enumerate(args):
        is_last = i == len(args) - 1

        found_dirs = matches_for_path(
            found_dirs,
            arg,
            allow_by_char=allow_by_char,
            expand_sep=(expand_last_sep and is_last),
            is_last=is_last,
            include_files=(not only_dir),
        )

        if found_dirs:
            nb_part = len(found_dirs[0].parts)
            nb_parts_last_arg = nb_part - nb_parts_prev_arg
            nb_parts_prev_arg = nb_part

        if not (i == 0 and arg in ("/", "~")):
            allow_by_char = False

    return found_dirs, max(nb_parts_last_arg, 0)
