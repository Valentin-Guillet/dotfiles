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

import shutil
import sys
import termios
import tty
from pathlib import Path


class TtyRaw:
    """ ContextManager to put the terminal in raw mode and reset it to previous config.
    This is so that we can capture one keypress at a time instead of waiting for enter.
    """

    def __enter__(self):
        self.stdin_fd = sys.stdin.fileno()
        self.old_settings = termios.tcgetattr(self.stdin_fd)

        tty.setraw(self.stdin_fd)

    def __exit__(self, exc_type, exc_value, exc_tb):
        termios.tcsetattr(self.stdin_fd, termios.TCSADRAIN, self.old_settings)


def colorize_blue(text):
    """ Insert bash color escape codes to render the given text in blue. """
    return "\033[01;34m" + text + "\033[0m"


def menu_with_options(options):
    """ Return a string representing a color-coded menu which presents a series of options.
    This uses flexible width columns, because fixed-width columns turned out to not look good.
    Example output:
        1. notes.git    2. projects.git
    """

    columns = shutil.get_terminal_size().columns
    output = []
    current_line = ""
    for i, option in enumerate(options):
        option = option.replace(str(Path.home()), "~")
        option_text = f"{i+1}. {colorize_blue(option)}"
        if len(current_line) + len(option) + len(str(i)) >= columns - 1:
            output.append(current_line)
            current_line = option_text
        else:
            if current_line:
                current_line += "    "
            current_line += option_text

    output.append(current_line)
    return "\n".join(output) + " "


def present_menu_with_options(options):
    """ Present all of the given options in a menu and collects input over STDIN.
    Return the chosen option, or None if the user's input was invalid or they hit CTRL+C.
    """

    options.sort()
    print(menu_with_options(options))

    with TtyRaw():
        char_input = sys.stdin.read(1)
        if not ("1" <= char_input <= "9"):
            return None

        choice = int(char_input)

        # We may require two characters with more than 10 choices.
        # If the second character is <Enter> (13), ignore it.
        if len(options) > 9 and choice <= len(options) // 10:
            char_input = sys.stdin.read(1)

            if "0" <= char_input <= "9":
                choice = 10 * choice + int(char_input)

            elif char_input != "\r":  # not a digit nor <Enter>
                return None

    if choice > len(options):
        return None

    return options[choice - 1]


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

        prev_index = index

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


def matches_by_chars(root, path_pattern):
    """ Return an array of all matches for a given tuple of single letter path parts,
    filtered by `filter_match()`.
    """
    found_dirs = [root]
    for char in path_pattern:
        dir_pattern_index = {}

        for directory in found_dirs:
            try:
                next(directory.iterdir())
            except (PermissionError, StopIteration):
                continue

            for subdir in directory.iterdir():
                if not subdir.is_dir():
                    continue

                name = subdir.name.lower() if char.islower() else subdir.name
                if char in name:
                    dir_pattern_index.setdefault(name.index(char), []).append(subdir)

        if not dir_pattern_index:
            return []

        found_dirs = dir_pattern_index[min(dir_pattern_index)]

    return found_dirs


def matches_for_path(path):
    """ Return an array of all matches for a given path, filtered by `filter_match()`.
    Each part of the path is a globed (fuzzy) match. For example:
      `p` matches `places/` and `suspects/`
      `p/h` matches `places/home` and `suspects/harry`
    """
    root = Path()
    path = path.replace(" ", "/")
    path_pattern = Path(path).parts

    # If start with home, add it to root
    home_parts = Path.home().parts
    if path_pattern[:len(home_parts)] == home_parts:
        root = Path.home()
        path_pattern = path_pattern[len(home_parts):]

    # If start with /, add it to root
    if path_pattern[0] in ("/", "//"):
        root = Path("/")
        path_pattern = path_pattern[1:]

    found_dirs = [root]
    for i, pattern in enumerate(path_pattern):
        if pattern == "..":
            found_dirs = [d.absolute().parent for d in found_dirs]
            continue

        new_found_dirs = []
        for directory in found_dirs:
            try:
                next(directory.iterdir())
            except (PermissionError, StopIteration):
                continue

            new_found_dirs.extend([subdir for subdir in directory.iterdir()
                                  if subdir.is_dir() and name_match(pattern, subdir.name)])

        found_dirs = filter_matches(pattern, new_found_dirs)

        # If no matching dir has been found for the first pattern and path
        # is only composed of one part, treat each character as a pattern
        if i == 0 and not found_dirs:
            found_dirs = matches_by_chars(root, tuple(pattern))

    return [str(directory) for directory in found_dirs]


def passthrough(cd_path):
    if not cd_path:
        return True

    if cd_path in (".", "/", "-", str(Path.home())):
        return True

    if cd_path.endswith("/"):
        return True

    if Path(cd_path).is_dir():
        return True

    return False


def main():
    cd_path = " ".join(sys.argv[1:])
    out_file = Path("/tmp/fuzzycd.out")

    # Just invoke cd directly in certain special cases
    if passthrough(cd_path):
        with out_file.open("w") as file:
            file.write("@passthrough")
        return

    matches = matches_for_path(cd_path)
    with out_file.open("w") as file:
        if not matches:
            file.write("@nomatches")
        elif len(matches) == 1:
            file.write(matches[0])
        elif len(matches) >= 100:
            print("There are more than 100 matches; be more specific.")
            file.write("@exit")
        else:
            choice = present_menu_with_options(matches)
            file.write(choice if choice else "@exit")


if __name__ == "__main__":
    main()
