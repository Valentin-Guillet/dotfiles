import sublime
import sublime_plugin
import re
from collections import defaultdict


class AlignBracketCommand(sublime_plugin.TextCommand):

	def run(self, edit):

		areas = list(self.view.sel())
		for area in reversed(areas):
			line = self.view.line(area)
			text = self.view.substr(line)

			prev_area = sublime.Region(line.a-1, line.a-1)
			prev_line = self.view.substr(self.view.line(prev_area))

			nb_brackets = 0
			for index in range(len(prev_line)-1, -1, -1):
				if prev_line[index] == ')':
					nb_brackets -= 1

				elif prev_line[index] == '(':
					nb_brackets += 1

				if nb_brackets > 0:
					break

			else:
				continue

			index_first_char = len(text) - len(text.lstrip())
			spaces = ' ' * (index - index_first_char + 1)
			self.view.insert(edit, line.a, spaces)
