
import sys
import atexit
import os
import readline


if sys.version_info > (3, 6):
    histfile = os.path.join(os.path.expanduser("~"), ".cache/history/python_history")

    try:
        readline.read_history_file(histfile)
        h_len = readline.get_current_history_length()
    except FileNotFoundError:
        open(histfile, 'wb').close()
        h_len = 0

    def save(prev_h_len, histfile):
        import readline
        new_h_len = readline.get_current_history_length()
        readline.set_history_length(1000)
        readline.append_history_file(new_h_len - prev_h_len, histfile)
        del readline

    atexit.register(save, h_len, histfile)

    del atexit, os, readline
    del histfile, h_len, save

del sys
