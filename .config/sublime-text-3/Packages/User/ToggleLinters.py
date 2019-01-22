import sublime
import sublime_plugin


class ToggleLintersCommand(sublime_plugin.TextCommand):
	def run(self, edit):
		settings = sublime.load_settings('SublimeLinter.sublime-settings')
		linters = settings.get("linters")

		for linter, setting in linters.items():
			disabled = setting['disable']
			linters[linter]['disable'] = not disabled

		settings.set('linters', linters)
		sublime.save_settings('SublimeLinter.sublime-settings')
