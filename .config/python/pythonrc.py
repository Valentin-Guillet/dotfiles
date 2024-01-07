import atexit
import os
import readline
import sys
from pathlib import Path


def write_history(history_path):
    import readline
    from pathlib import Path
    try:
        Path(history_path).parent.mkdir(parents=True, exist_ok=True)
        readline.write_history_file(history_path)
    except OSError:
        pass

if sys.version_info > (3, 6):
    cache_dir = Path(os.environ.get("XDG_CACHE_HOME") or "~/.cache").expanduser()
    history_file = cache_dir / "python" / "history"

    readline.set_history_length(10000)
    try:
        readline.read_history_file(history_file)
    except FileNotFoundError:
        pass

    # Prevents creation of default history if custom is empty
    if readline.get_current_history_length() == 0:
        readline.add_history("# History creation")

    atexit.register(write_history, history_file)

del atexit, os, readline, sys
del cache_dir, history_file
del Path
