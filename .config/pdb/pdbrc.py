
import readline
import atexit

# Command line history:
histfile = os.path.expanduser("~/.cache/history/python_history")
if readline.get_current_history_length() == 0:
    try:
        readline.read_history_file(histfile)
    except IOError:
        pass

atexit.register(readline.write_history_file, histfile)

# Cleanup any variables that could otherwise clutter up the namespace.
try:
    del os
    del readline
    del atexit
    del histfile

except NameError:
    pass

