
import asyncio

from prompt_toolkit.application.current import get_app
from prompt_toolkit.buffer import Buffer
from prompt_toolkit.buffer import logger as buffer_logger
from prompt_toolkit.enums import DEFAULT_BUFFER, EditingMode
from prompt_toolkit.filters import (
    Condition,
    emacs_insert_mode,
    has_focus,
    has_selection,
    vi_insert_mode,
    vi_insert_multiple_mode,
    vi_navigation_mode,
    vi_replace_mode,
)
from prompt_toolkit.formatted_text import to_formatted_text
from prompt_toolkit.key_binding.bindings.named_commands import get_by_name
from prompt_toolkit.key_binding.vi_state import InputMode
from prompt_toolkit.keys import Keys
from ptpython.completer import JediCompleter
from ptpython.history_browser import PythonHistory
from ptpython.layout import CompletionVisualisation
from ptpython.prompt_style import PromptStyle
from ptpython.python_input import PythonInput

__all__ = ["configure"]


# Cf. https://pygments.org/docs/tokens/
_custom_ui_colorscheme = {
    "pygments.keyword.constant": "#ae81ff",
    "pygments.keyword.namespace": "#f9065f",
    "pygments.literal.string": "#ffff87",
    "pygments.name.builtin.pseudo": "#fc8803",
    "pygments.name.decorator": "#fc8803",
    "pygments.name.variable.magic": "#fc8803",
    "pygments.operator": "#f9065f",

    "pygments.comment.preprocfile": "#008000",    # cf. fix_traceback_file_color()
    "pygments.generic.traceback": "#0044dd",
    "pygments.generic.error": "#e40000",
}

# GENERAL CONFIGURATION

def configure(repl):
    """
    Configuration method. This is called during the start-up of ptpython.

    :param repl: `PythonRepl` instance.
    """
    repl.accept_input_on_enter = 3
    repl.completion_visualisation = CompletionVisualisation.POP_UP
    repl.complete_while_typing = False
    repl.confirm_exit = False
    repl.enable_auto_suggest = False      # Line completion from history
    repl.enable_input_validation = True
    repl.enable_open_in_editor = True     # 'C-x C-e' (emacs) or 'v' (vim)
    repl.enable_syntax_highlighting = True
    repl.enable_system_bindings = True    # Enables Ctrl-Z
    repl.highlight_matching_parenthesis = True
    repl.insert_blank_line_after_output = False
    repl.show_docstring = False
    repl.show_meta_enter_message = True
    repl.show_signature = False
    repl.show_status_bar = False

    set_prompt_style(repl)

    repl.use_code_colorscheme("monokai")
    apply_custom_colorscheme(repl, _custom_ui_colorscheme)
    fix_traceback_file_color()

    # `kj` to escape vi-mode
    @repl.add_key_binding("k", "j", filter=vi_insert_mode | vi_insert_multiple_mode | vi_replace_mode)
    def _(event):
        repl.app.vi_state.input_mode = InputMode.NAVIGATION

    # `M-v` to switch between emacs- and vi-mode
    @repl.add_key_binding("escape", "v")
    def _(event):
        repl.vi_mode = not repl.vi_mode

    # `M-c` to show function docstring
    @repl.add_key_binding("escape", "c")
    def _(event):
        repl.show_docstring = not repl.show_docstring

    # `M-x` to show function signature
    @repl.add_key_binding("escape", "x")
    def _(event):
        repl.show_signature = not repl.show_signature

    # Case modification
    repl.add_key_binding("c-x", "c-l", filter=emacs_insert_mode)(get_by_name("downcase-word"))
    repl.add_key_binding("c-x", "c-u", filter=emacs_insert_mode)(get_by_name("uppercase-word"))
    repl.add_key_binding("c-x", "c-h", filter=emacs_insert_mode)(get_by_name("capitalize-word"))

    # `C-v` instead of `C-q` to insert literal character
    repl.add_key_binding("c-v", filter=~has_selection & ~vi_navigation_mode)(get_by_name("quoted-insert"))

    # `M-m` and `M-i` to add `help()` and `dir()` around line
    add_around_line(repl, "help", ("escape", "m"))
    add_around_line(repl, "dir", ("escape", "i"))

    fix_buffer_pre_run_callables()
    set_history_search(repl)
    set_revert_line(repl)
    set_transpose_words(repl)
    set_emacs_bindings_in_vi_insert(repl)
    fix_operate_and_get_next(repl)
    fix_history()

    autocomplete_add_bracket_after_function(repl)

    corrections_space = {
        "improt": "import",
    }
    set_abbreviations(repl, corrections_space, " ")

    corrections_bracket = {
        "pritn": "print",
        "brekapoint": "breakpoint",
        "breakpoitn": "breakpoint",
        "brekapoitn": "breakpoint",
    }
    set_abbreviations(repl, corrections_bracket, "(")


# UTILS

def find_default_binding(repl, function_name):
    for binding in repl.app._default_bindings.bindings:
         if function_name in binding.handler.__qualname__:
             return binding
    return None


# ABBREVIATIONS / CORRECTIONS

def set_abbreviations(repl, abbreviations, key):
    @repl.add_key_binding(key)
    def _(event):
        b = event.cli.current_buffer
        w = b.document.get_word_before_cursor()
        if w is not None and w in abbreviations:
            b.delete_before_cursor(count=len(w))
            b.insert_text(abbreviations[w])
        b.insert_text(key)


# AUTOCOMPLETE BRACKET AFTER FUNCTION

# To get brackets after function completion, we first activate the jedi
# option for it. But there's two issues then:
# 1. for an obscure reason, when the application layout is created, the
#    pop-up window is passed with a `menu_position()` function that sets
#    its horizontal position to the first bracket of the completion
#    suggestion (cf. ptpython/layout.py:L594-605)
#    This makes the window jump horizontally when going through the
#    completion list, so we remove this function (its a member of a
#    BufferControl object created here: ptpython/layout.py:L608)
# 2. the JediCompleter class automatically add a pair of brackets after
#    a function, so with the added bracket this becomes "(()". We
#    overwrite the function to modify the suffix to only ")"

def autocomplete_add_bracket_after_function(repl):
    import jedi.settings
    jedi.settings.add_bracket_after_function = True

    # 1.
    repl.ptpython_layout.root_container.children[0].children[0] \
        .children[0].content.children[0].content.menu_position = None

    # 2.
    orig_get_completions = JediCompleter.get_completions

    def my_get_completions(self, *args, **kwargs):
        completions = orig_get_completions(self, *args, **kwargs)
        for jc in completions:
            if jc._display_meta == "function":
                jc.display = to_formatted_text(jc.text + ")")
            yield jc

    JediCompleter.get_completions = my_get_completions


# COLORSCHEME

def apply_custom_colorscheme(repl, colorscheme):
    curr_style = repl.code_styles[repl._current_code_style_name]
    curr_style.style_rules.extend(list(colorscheme.items()))
    repl._current_style = repl._generate_style()

# In traceback messages, pygments tokenize the file in which the error is found as
# Name.Builtin (cf. pygments/lexers/python.py:L748-752), so we can't color it
# differently than builtin functions
# We therefore modify the lexer to replace the Name.Builtin tokens with
# Comment.PreprocFile tokens, as these are not used in Python
def fix_traceback_file_color():
    from pygments.lexer import bygroups
    from pygments.lexers.python import PythonTracebackLexer
    from pygments.token import Comment, Name, Number, Text, Whitespace

    patt, _ = PythonTracebackLexer.tokens["intb"][0]
    new_cb = bygroups(Text, Comment.PreprocFile, Text, Number, Text, Name, Whitespace)
    PythonTracebackLexer.tokens["intb"][0] = (patt, new_cb)

    patt, _ = PythonTracebackLexer.tokens["intb"][1]
    new_cb = bygroups(Text, Comment.PreprocFile, Text, Number, Whitespace)
    PythonTracebackLexer.tokens["intb"][1] = (patt, new_cb)


# EMACS BINDINGS IN VI INSERT MODE

@Condition
def not_empty_line_filter():
    app = get_app()
    return bool(app.current_buffer.document.current_line)

def set_emacs_bindings_in_vi_insert(repl):
    focused_insert = has_focus(DEFAULT_BUFFER) & vi_insert_mode

    # Filter on non-empty line to keep the exit-repl default binding
    repl.add_key_binding("c-d", filter=focused_insert & not_empty_line_filter)(get_by_name("delete-char"))

    keys_cmd_dict = {
        ("c-a", ): get_by_name("beginning-of-line"),
        ("c-b", ): get_by_name("backward-char"),
        ("c-e", ): get_by_name("end-of-line"),
        ("c-f", ): get_by_name("forward-char"),
        ("c-k", ): get_by_name("kill-line"),
        ("c-w", ): get_by_name("unix-word-rubout"),
        ("c-y", ): get_by_name("yank"),
        ("c-_", ): get_by_name("undo"),
        ("c-x", "c-e"): get_by_name("edit-and-execute-command"),
        ("c-x", "e"): get_by_name("edit-and-execute-command"),
        ("escape", "b"): get_by_name("backward-word"),
        ("escape", "d"): get_by_name("kill-word"),
        ("escape", "f"): get_by_name("forward-word"),
        ("escape", "c-h" ): get_by_name("backward-kill-word"),
    }

    for keys, cmd in keys_cmd_dict.items():
        repl.add_key_binding(*keys, filter=focused_insert)(cmd)


# FIX BUFFER PRE RUN CALLABLES

# There seems to be a bug in the prompt_toolkit Application class regarding
# the use of pre_run_callables, due to the asynchronous nature of the code.
# Indeed, the callbacks in the `app.pre_run_callables` list are executed right
# after the `buffer` object is reset, and before it is filled again with the
# REPL history.
# This is an issue for the `operate_and_get_next` function which needs the Buffer
# object to be filled in order to get the next line from history.
#
# To solve this issue, we add a new list of callbacks to the Buffer class, and
# execute them after the history has been loaded (which is defined in the
# `load_history_if_not_yet_loaded` method that we overwrite)
#
# We also define a `Buffer.add_pre_run_callable` helper method that adds a callback
# to this new `fixed_pre_run_callbacks` list
def new_load_history_if_not_yet_loaded(self):
    if self._load_history_task is None:
        async def load_history():
            async for item in self.history.load():
                self._working_lines.appendleft(item)
                self._Buffer__working_index += 1

            if hasattr(self, "fixed_pre_run_callbacks"):
                for c in self.fixed_pre_run_callbacks:
                    c(self)
                del self.fixed_pre_run_callbacks[:]

        self._load_history_task = get_app().create_background_task(load_history())
        def load_history_done(f) -> None:
            try:
                f.result()
            except asyncio.CancelledError:
                pass
            except GeneratorExit:
                pass
            except BaseException:
                buffer_logger.exception("Loading history failed")
        self._load_history_task.add_done_callback(load_history_done)

def add_pre_run_callable(self, callback):
    if not hasattr(self, "fixed_pre_run_callbacks"):
        self.fixed_pre_run_callbacks = []
    self.fixed_pre_run_callbacks.append(callback)

def fix_buffer_pre_run_callables():
    Buffer.load_history_if_not_yet_loaded = new_load_history_if_not_yet_loaded
    Buffer.add_pre_run_callable = add_pre_run_callable


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

    @history.app.key_bindings.add("escape", "x")
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
    main_buffer_focused = has_focus(history.history_buffer) | has_focus(history.default_buffer)

    @history.app.key_bindings.add("escape", filter=main_buffer_focused)
    def _(event):
        event.app.exit(result=None)

def fix_history():
    PythonInput.enter_history = new_enter_history


# HISTORY SEARCH

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


# LINE MODIFICATIONS

def add_around_line(repl, text, keys):
    @repl.add_key_binding(*keys)
    def _(event):
        buff = event.current_buffer
        prev_text = buff.text
        event.app.clipboard.set_text(prev_text)
        buff.text = text + "(" + buff.text.rsplit("(", 1)[0] + ")"
        buff.cursor_position += buff.document.get_end_of_line_position()

        def yank_prev_text(buffer):
            buffer.text = prev_text
            buffer.cursor_position += buffer.document.get_end_of_line_position()

        buff.add_pre_run_callable(yank_prev_text)
        buff.validate_and_handle()


# OPERATE-AND-GET-NEXT FIX

# The `operate-and-get-next` key_binding is broken due to an async error.
# The original `operate_and_get_next` function adds a callback to the
# `app.pre_run_callables` list, but as the code is asynchronous, this callback
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

    def set_working_index(buffer):
        if new_index < len(buffer._working_lines):
            buffer.working_index = new_index
            buffer.cursor_position += buffer.document.get_end_of_line_position()

    buff.add_pre_run_callable(set_working_index)

def fix_operate_and_get_next(repl):
    operate_binding = find_default_binding(repl, "operate_and_get_next")
    if operate_binding:
        operate_binding.handler = my_operate_and_get_next


# PROMPT STYLE

class CustomPrompt(PromptStyle):
    def __init__(self, python_input):
        self.python_input = python_input

    def in_prompt(self):
        if self.python_input.vi_mode:
            if self.python_input._app.vi_state.input_mode == InputMode.NAVIGATION:
                return [("class:prompt", "n>> ")]
            elif self.python_input._app.vi_state.input_mode == InputMode.INSERT:
                return [("class:prompt", "i>> ")]
            elif self.python_input._app.vi_state.input_mode == InputMode.INSERT_MULTIPLE:
                return [("class:prompt", "I>> ")]
            elif self.python_input._app.vi_state.input_mode == InputMode.REPLACE_SINGLE:
                return [("class:prompt", "r>> ")]
            elif self.python_input._app.vi_state.input_mode == InputMode.REPLACE:
                return [("class:prompt", "R>> ")]
        return [("class:prompt", ">>> ")]

    def in2_prompt(self, width):
        return [("class:prompt.dots", "...")]

    def out_prompt(self):
        return []

def set_prompt_style(repl):
    repl.all_prompt_styles["custom"] = CustomPrompt(repl)
    repl.prompt_style = "custom"


# REVERT LINE

# We replace the `Buffer._set_text` method to save a copy of the currently
# modified line to be reverted by the `M-r` keybinding
# When reverting, we check whether a version of the line has been saved,
# we restore it if needed and we clear it from the revert memory.
# We also modify the accept handler of the default buffer to clear the
# memory when accepting an input, as the modifications made on any line
# are not saved anyway

def new_set_text(self, value):
    working_index = self.working_index
    working_lines = self._working_lines

    original_value = working_lines[working_index]
    working_lines[working_index] = value

    # Saving original line in revert memory if we're modifying line from the history
    # (i.e. not the last one as it corresponds to the new input line)
    if working_index < len(working_lines) - 1 and working_index not in self._revert_line_memory:
        self._revert_line_memory[working_index] = original_value

    return len(value) != len(original_value) or value != original_value

def revert_line(self):
    # Clear text when reverting on new input line
    if self.working_index == len(self._working_lines) - 1:
        self.text = ""
        return

    # Nothing to revert
    if self.working_index not in self._revert_line_memory:
        return

    self.text = self._revert_line_memory[self.working_index]
    self.cursor_position += self.document.get_end_of_line_position()
    del self._revert_line_memory[self.working_index]

def wrap_accept(handler):
    def wrapped_handler(self, *args, **kwargs):
        self._revert_line_memory.clear()
        return handler(self, *args, **kwargs)
    return wrapped_handler

def set_revert_line(repl):
    @repl.add_key_binding("escape", "r", filter=has_focus(repl.default_buffer))
    def _(event):
        event.current_buffer.revert_line()

    Buffer._revert_line_memory = {}
    Buffer._set_text = new_set_text
    Buffer.revert_line = revert_line

    repl.default_buffer.accept_handler = wrap_accept(repl.default_buffer.accept_handler)


# TRANPOSE WORDS

# Using the defined `Buffer` and `Document` methods introduced issues
# with respect to word definions, so instead we reimplement exactly
# the same operationa as readline in bash source code (cf. `transpose_words`
# definition in lib/readline/text.c)
def set_transpose_words(repl):
    @repl.add_key_binding("escape", "t", filter=has_focus(DEFAULT_BUFFER) & emacs_insert_mode)
    @repl.add_key_binding("g", "t", filter=has_focus(DEFAULT_BUFFER) & vi_navigation_mode)
    def _(event):
        buff = event.current_buffer
        text = buff.text
        pos = buff.cursor_position

        # Find end of word_2: first goto first alnum char,
        # then continue until non-alnum char
        while pos < len(text) and not text[pos].isalnum():
            pos += 1
        while pos < len(text) and text[pos].isalnum():
            pos += 1
        w2_end = pos

        # Find the beginning of word_2: we still start by
        # checking for non-alnum chars in the case where
        # there was no chars after cursor (so w2_end is
        # the end of line)
        while pos > 0 and not text[pos - 1].isalnum():
            pos -= 1
        while pos > 0 and text[pos - 1].isalnum():
            pos -= 1
        w2_beg = pos

        while pos > 0 and not text[pos - 1].isalnum():
            pos -= 1
        w1_end = pos
        while pos > 0 and text[pos - 1].isalnum():
            pos -= 1
        w1_beg = pos

        if w1_beg == w1_end or w2_beg == w2_end or w1_beg == w2_beg or w2_beg < w1_end:
            return

        new_text  = text[       : w1_beg]
        new_text += text[w2_beg : w2_end]
        new_text += text[w1_end : w2_beg]
        new_text += text[w1_beg : w1_end]
        new_text += text[w2_end :       ]
        buff.text = new_text
        buff.cursor_position = w2_end
