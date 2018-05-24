import sublime
import sublime_plugin


class AddNextWordCommand(sublime_plugin.TextCommand):
	def run(self, edit):
		regions = list(self.view.sel())
		self.view.run_command('move', {"by": "words", "forward":True})
		self.view.run_command('expand_selection', {"to": "word"})
		self.view.sel().add_all(regions)
