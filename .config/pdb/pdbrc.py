
import atexit
import os
import pdb
import readline
import rlcompleter


# Command line history:
cache_dir = os.path.expanduser("~/.cache/python")
os.makedirs(cache_dir, exist_ok=True)
histfile = os.path.join(cache_dir, "history")
if readline.get_current_history_length() == 0:
    try:
        readline.read_history_file(histfile)
    except IOError:
        pass

atexit.register(readline.write_history_file, histfile)

# Autocomplete
pdb.Pdb.complete = rlcompleter.Completer(locals() | globals()).complete

# Cleanup any variables that could otherwise clutter up the namespace.
try:
    del atexit
    del histfile
    del os
    del pdb
    del readline
    del rlcompleter

except NameError:
    pass

