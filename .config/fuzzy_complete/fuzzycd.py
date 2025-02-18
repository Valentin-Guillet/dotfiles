#!/usr/bin/env -S python3 -B

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

from fuzzy_lib import find_matching_dirs


class TtyRaw:
    """ ContextManager to put the terminal in raw mode and reset it to previous config.
    This is so that we can capture one keypress at a time instead of waiting for enter.
    """

    def __enter__(self):
        self.stdin_fd = sys.stdin.fileno()
        self.old_settings = termios.tcgetattr(self.stdin_fd)

        tty.setraw(self.stdin_fd)

    def __exit__(self, *_):
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


def passthrough(cd_args):
    if not cd_args:
        return True

    if len(cd_args) != 1:
        return False

    cd_path = cd_args[0]
    if cd_path in (".", "/", "-", str(Path.home())):
        return True

    if cd_path.endswith("/"):
        return True

    return Path(cd_path).is_dir()


def main():
    cd_args = sys.argv[1:]
    out_file = Path("/tmp/fuzzycd.out")

    # Just invoke cd directly in certain special cases
    if passthrough(cd_args):
        with out_file.open("w") as file:
            file.write("@passthrough")
        return

    found_dirs, _ = find_matching_dirs(cd_args, only_dir=True, expand_last_sep=False)
    matches = [str(found_dir) for found_dir in found_dirs]

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
