import sublime
import sublime_plugin
import re


class ToggleDebugCommentCommand(sublime_plugin.TextCommand):

	def run(self, edit, action):
		areas_to_comment = self.view.find_all('^(\s*)([^#\n]*# debug)$')
		areas_to_uncomment = self.view.find_all('^(\s*)# (.*# debug)$')

		if action == "comment" or action == "toggle":
			for area in areas_to_comment[::-1]:
				text = self.view.substr(area)
				modified_text = re.sub(r'^(\s*)(.*# debug)$', r'\1# \2', text)
				self.view.replace(edit, area, modified_text)

		if action == "uncomment" or action == "toggle":
			for area in areas_to_uncomment[::-1]:
				text = self.view.substr(area)
				modified_text = re.sub(r'^(\s*)# (.*# debug)$', r'\1\2', text)
				self.view.replace(edit, area, modified_text)
