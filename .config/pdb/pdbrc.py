
import atexit
import readline
import rlcompleter
import pdb

# Command line history:
histfile = os.path.expanduser("~/.cache/history/python_history")
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
    del readline
    del rlcompleter
    del pdb

except NameError:
    pass

