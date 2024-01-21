
import atexit
import os
import readline
from pathlib import Path

# Command line history:
_pdb_cache_dir = Path(os.environ.get("XDG_CACHE_HOME", "~/.cache")).expanduser()/"python"
_pdb_cache_dir.mkdir(parents=True, exist_ok=True)
_pdb_histfile = _pdb_cache_dir/"history"
if readline.get_current_history_length() == 0:
    try:
        readline.read_history_file(_pdb_histfile)
    except OSError:
        pass

atexit.register(readline.write_history_file, _pdb_histfile)

# Cleanup any variables that could otherwise clutter up the namespace.
try:
    del _pdb_cache_dir
    del _pdb_histfile

    del atexit
    del os
    del readline

except NameError:
    pass

