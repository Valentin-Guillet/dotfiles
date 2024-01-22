
from prompt_toolkit.filters import ViInsertMode
from prompt_toolkit.key_binding.key_processor import KeyPress
from prompt_toolkit.keys import Keys
from ptpython.layout import CompletionVisualisation

__all__ = ["configure"]


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
    repl.enable_history_search = True
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

    # `kj` to escape vi-mode
    @repl.add_key_binding("k", "j", filter=ViInsertMode())
    def _(event):
        event.cli.key_processor.feed(KeyPress(Keys("escape")))

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

