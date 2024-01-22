
import asyncio

from prompt_toolkit.application.current import get_app
from prompt_toolkit.buffer import Buffer
from prompt_toolkit.buffer import logger as buffer_logger
from prompt_toolkit.enums import EditingMode
from prompt_toolkit.filters import HasFocus, ViInsertMode
from prompt_toolkit.key_binding.bindings.named_commands import _readline_commands
from prompt_toolkit.key_binding.key_bindings import key_binding
from prompt_toolkit.key_binding.key_processor import KeyPress
from prompt_toolkit.key_binding.vi_state import InputMode
from prompt_toolkit.keys import Keys
from ptpython.history_browser import PythonHistory
from ptpython.layout import CompletionVisualisation
from ptpython.python_input import PythonInput

__all__ = ["configure"]


# UTILS

def find_default_binding(repl, function_name):
    for binding in repl.app._default_bindings.bindings:
         if function_name in binding.handler.__qualname__:
             return binding
    return None


# GENERAL CONFIGURATION

def configure(repl):
    """
    Configuration method. This is called during the start-up of ptpython.

    :param repl: `PythonRepl` instance.
    """
    repl.completion_visualisation = CompletionVisualisation.POP_UP
    repl.complete_while_typing = False
    repl.confirm_exit = False
    repl.enable_auto_suggest = False      # Line completion from history
    repl.enable_fuzzy_completion = True
    repl.enable_input_validation = True
    repl.enable_mouse_support = True
    repl.enable_open_in_editor = True     # 'C-x C-e' (emacs) or 'v' (vim)
    repl.enable_syntax_highlighting = True
    repl.enable_system_bindings = True    # Enables Ctrl-Z
    repl.highlight_matching_parenthesis = True
    repl.insert_blank_line_after_output = False
    repl.show_docstring = False
    repl.show_meta_enter_message = True
    repl.show_signature = False
    repl.show_status_bar = True

    @repl.add_key_binding("escape", "b")
    def _(event):
        breakpoint()

    # `kj` to escape vi-mode
    @repl.add_key_binding("k", "j", filter=ViInsertMode())
    def _(event):
        event.cli.key_processor.feed(KeyPress(Keys("escape")))

    # `M-v` to switch between emacs- and vi-mode
    @repl.add_key_binding("escape", "v")
    def _(event):
        repl.vi_mode = not repl.vi_mode

    # Simple autocorrections
    def add_abbrev(abbreviations, key):
        @repl.add_key_binding(key)
        def _(event):
            b = event.cli.current_buffer
            w = b.document.get_word_before_cursor()
            if w is not None and w in abbreviations:
                b.delete_before_cursor(count=len(w))
                b.insert_text(abbreviations[w])
            b.insert_text(key)

    corrections_space = {
        "impotr": "import",
    }
    add_abbrev(corrections_space, " ")

    corrections_bracket = {
        "pritn": "print",
        "brekapoint": "breakpoint",
        "breakpoitn": "breakpoint",
        "brekapoitn": "breakpoint",
    }
    add_abbrev(corrections_bracket, "(")

    set_history_search(repl)
    fix_history()
    fix_operate_and_get_next(repl)


# SET HISTORY SEARCH

# By default, [Up|Down] and [C-p|C-n] do the same thing. Here, we modify
# these key bindings so that [Up|Down] set `repl.enable_history_search`
# to True before calling handler (so we only search in history), whereas
# [C-p|C-n] set it to false (so we don't search in history)
def set_history_search(repl):
    def wrap_handler(repl, enable_history_search, handler):
        def wrapped_handler(event):
            repl.enable_history_search = enable_history_search
            handler(event)
        return wrapped_handler

    up_binding = find_default_binding(repl, "load_basic_bindings.<locals>._go_up")
    up_binding.handler = wrap_handler(repl, True, up_binding.handler)

    down_binding = find_default_binding(repl, "load_basic_bindings.<locals>._go_down")
    down_binding.handler = wrap_handler(repl, True, down_binding.handler)

    c_p_binding = find_default_binding(repl, "load_emacs_bindings.<locals>._prev")
    c_p_binding.handler = wrap_handler(repl, False, c_p_binding.handler)

    c_n_binding = find_default_binding(repl, "load_emacs_bindings.<locals>._next")
    c_n_binding.handler = wrap_handler(repl, False, c_n_binding.handler)


# HISTORY FIX

# The `PythonInput.enter_history` is bugged: it does not control the input
# mode correctly. There's two errors:
# 1. The editing mode of the history app is not set, so the keybindings are
#    always the one of EMACS by default, even if `python_input.vi_mode` is True
# 2. As the history app and the main REPL share the same PythonInput object,
#    the input mode must be saved and restored after exiting the history tab
#
# In addition, we set the default input mode as VI in history tab, and we call
# a custom function on the PythonHistory object in order to customize key bindings
# (cf. setup_history_keybindings below)
def new_enter_history(self):
    app = self.app
    app.vi_state.input_mode = InputMode.NAVIGATION

    saved_vi_mode = self.vi_mode    # Cf issue 2.

    history = PythonHistory(self, self.default_buffer.document)

    # Setup user keybindings
    setup_history_keybindings(history)

    # Default input mode to VI
    self.vi_mode = True
    history.app.editing_mode = EditingMode.VI   # Cf issue 1.

    import asyncio

    from prompt_toolkit.application import in_terminal

    async def do_in_terminal() -> None:
        async with in_terminal():
            result = await history.app.run_async()
            if result is not None:
                self.default_buffer.text = result

            app.vi_state.input_mode = InputMode.INSERT

            # Restore saved input mode (cf issue 2.)
            self.vi_mode = saved_vi_mode

    asyncio.ensure_future(do_in_terminal())

# There seem to be no easy way to modify the history tab shortcuts, as a
# new `PythonHistory` object is created each time we press the history key,
# which redefines its shortcuts. So we define a custom function that modifies
# the default keybindings, and insert it in the creation of the `PythonHistory`
# object. As we redefine the `enter_history` function in which the history
# object is created (cf. above), we can add it here.
# NB: if we did not redefine this function, another solution would be to
# monkey patch the `PythonHistorty.__init__` method
def setup_history_keybindings(history):
    # Fix editing mode issue
    history.app.key_bindings.remove("f4")

    @history.app.key_bindings.add("escape", "v")
    @history.app.key_bindings.add("f4")
    def _(event):
        history.python_input.vi_mode = not history.python_input.vi_mode
        if history.python_input.vi_mode:
            event.app.editing_mode = EditingMode.VI
        else:
            event.app.editing_mode = EditingMode.EMACS

    # We want to modify / remove bindings from the default key bindings
    # in the history tab, such as q to record a macro in Vi mode
    # The default key bindings are in `history.app._default_bindings`,
    # which is a _MergedKeyBindings object.
    # This object has a list of all bindings in `_bindings2.bindings`,
    # which is populated when getting the property `bindings`
    # So first, we call the property to populate `_bindings2`
    _ = history.app._default_bindings.bindings

    # Then, we can remove `q` from default bindings to get it to
    # exit history instead of recording a macro
    history.app._default_bindings._bindings2.remove("q", Keys.Any)

    # Similarly, we remove `escape` that switches from Vi insert mode
    # to navigation mode (useless in history)
    history.app._default_bindings._bindings2.remove("escape")

    # We can now add `escape` to quit the history tab
    main_buffer_focused = HasFocus(history.history_buffer) | HasFocus(history.default_buffer)

    @history.app.key_bindings.add("escape", filter=main_buffer_focused)
    def _(event):
        event.app.exit(result=None)

def fix_history():
    PythonInput.enter_history = new_enter_history


# OPERATE-AND-GET-NEXT FIX

# The `operate-and-get-next` key_binding is broken due to an async error.
# The original `operate_and_get_next` function adds a callback to the
# `app.pre_run_callables` list, but as the code is asynchrone, this callback
# is executed right after the `buffer` object is reset, and before it is filled
# again with the REPL history. So when executing the `set_working_index`
# callback, the `buff._working_lines` list is empty, so the callback does nothing.
# The only way to fix this I found is to execute the callback right after
# the history has been filled again, which is done in the asynchronous `load_history`
# function in the `load_history_if_not_yet_loaded` Buffer method.
#
# So, we overwrite this function with our version of `load_history`, that checks
# and go to a specific history line (after a `C-o` input) if a new buffer variable
# called `operate_saved_working_index` has been set
def my_operate_and_get_next(event):
    buff = event.current_buffer
    new_index = buff.working_index + 1
    buff.validate_and_handle()
    def set_working_index():
        buff.operate_saved_working_index = new_index
    event.app.pre_run_callables.append(set_working_index)

def new_load_history_if_not_yet_loaded(self):
    if self._load_history_task is None:
        async def load_history():
            async for item in self.history.load():
                self._working_lines.appendleft(item)
                self._Buffer__working_index += 1

            if hasattr(self, "operate_saved_working_index") and self.operate_saved_working_index < len(self._working_lines):
                self._Buffer__working_index = self.operate_saved_working_index
                self.cursor_position += self.document.get_end_of_line_position()
                del self.operate_saved_working_index

        self._load_history_task = get_app().create_background_task(load_history())
        def load_history_done(f: asyncio.Future[None]) -> None:
            try:
                f.result()
            except asyncio.CancelledError:
                pass
            except GeneratorExit:
                pass
            except BaseException:
                buffer_logger.exception("Loading history failed")
        self._load_history_task.add_done_callback(load_history_done)

def fix_operate_and_get_next(repl):
    # Find the default binding that corresponds to "operate-and-get-next"
    # and replace it with our custom function
    operate_binding = find_default_binding(repl, "operate_and_get_next")
    if operate_binding:
        operate_binding.handler = my_operate_and_get_next

    Buffer.load_history_if_not_yet_loaded = new_load_history_if_not_yet_loaded
