
import pdb

from pygments.formatters import TerminalTrueColorFormatter


class Config(pdb.DefaultConfig):
    sticky_by_default = True
    formatter = TerminalTrueColorFormatter(style="monokai")


def setup_history():
    import atexit
    import os
    import readline
    from pathlib import Path

    # Command line history:
    cache_dir = Path(os.environ.get("XDG_CACHE_HOME", "~/.cache")).expanduser()/"python"
    cache_dir.mkdir(parents=True, exist_ok=True)
    histfile = cache_dir/"history"
    if readline.get_current_history_length() == 0:
        try:
            readline.read_history_file(histfile)
        except OSError:
            pass

    atexit.register(readline.write_history_file, histfile)

setup_history()
