import sublime
import sublime_plugin


class RemoveClosingBracket(sublime_plugin.TextCommand):
	def run(self, edit):

		curr_point = self.view.sel()[0]
		region_line = self.view.line(curr_point)
		line = self.view.substr(region_line)
		
		row, col = self.view.rowcol(curr_point.begin())

		try:
			i = col
			nb_brackets = 1

			while nb_brackets > 0:
				if line[i] == '(':
					nb_brackets += 1
				elif line[i] == ')':
					nb_brackets -= 1
				i += 1

			index_closing_bracket = self.view.text_point(row, i - 1)
			region = sublime.Region(index_closing_bracket, index_closing_bracket+1)
			self.view.erase(edit, region)

		except (ValueError, IndexError):
			pass

		self.view.run_command('left_delete')

