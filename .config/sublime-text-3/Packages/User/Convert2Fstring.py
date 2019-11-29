import sublime
import sublime_plugin


class ConvertToFstringCommand(sublime_plugin.TextCommand):

	def run(self, edit):
		
		n = len(self.view.sel())

		for index in range(n):

			curr_point = self.view.sel()[index]
			line = self.view.lines(curr_point)

			whole_region = sublime.Region(0, self.view.size())
			text = self.view.substr(whole_region)

			i = curr_point.begin() - 1
			while text[i] != '"' and text[i] != "'" and text[i] != '\n':
				i -= 1

			if text[i] != '\n':
				self.view.insert(edit, i, 'f')
