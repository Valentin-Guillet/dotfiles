
import contextlib
import sys


def setup_history_path():
    import atexit
    import contextlib
    import os
    import readline
    from pathlib import Path


    def write_history(history_path):
        import readline
        from pathlib import Path
        try:
            Path(history_path).parent.mkdir(parents=True, exist_ok=True)
            readline.write_history_file(history_path)
        except OSError:
            pass

    cache_dir = Path(os.environ.get("XDG_CACHE_HOME") or "~/.cache").expanduser()
    history_file = cache_dir / "python" / "history"

    readline.set_history_length(10000)
    with contextlib.suppress(FileNotFoundError):
        readline.read_history_file(history_file)

    # Prevents creation of default history if custom is empty
    if readline.get_current_history_length() == 0:
        readline.add_history("# History creation")

    atexit.register(write_history, history_file)


if "ptpython" not in sys.modules:
    setup_history_path()
else:
    with contextlib.suppress(ImportError):
        import pdir as dir     # noqa


del contextlib
del sys
del setup_history_path
