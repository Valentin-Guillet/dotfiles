import sublime
import sublime_plugin


class LastSelectionCommand(sublime_plugin.TextCommand):

    def run(self, edit):
        if len(self.view.sel()):
            last = self.view.sel()[-1]
            self.view.sel().clear()
            self.view.sel().add(last)
