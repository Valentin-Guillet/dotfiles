import sublime
import sublime_plugin
import re


class RemoveDebugCommand(sublime_plugin.TextCommand):
	def run(self, edit):
		region = sublime.Region(0, self.view.size())
		new_text = re.sub(".*# debug\n", '', self.view.substr(region))
		self.view.replace(edit, region, new_text)
