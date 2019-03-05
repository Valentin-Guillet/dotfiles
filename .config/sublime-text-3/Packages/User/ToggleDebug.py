import sublime
import sublime_plugin
import re


class ToggleDebugCommand(sublime_plugin.TextCommand):

	def run(self, edit):

		selections = list(self.view.sel())[::-1]
		for sel in selections:
			for line in self.view.lines(sel)[::-1]:
				text = self.view.substr(line)
				if re.match(r'^.*\s*# debug\s*$', text):
					modified_text = re.sub(r'^(.*?)\s*# debug\s*$', r'\1', text)
				else:
					modified_text = text + '        # debug'
				self.view.replace(edit, line, modified_text)
