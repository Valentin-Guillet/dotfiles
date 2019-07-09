import sublime
import sublime_plugin
import re


class ToggleDebugCommentCommand(sublime_plugin.TextCommand):

    def is_selected(self, area):
        selections = list(self.view.sel())
        if len(selections) == 1 and len(selections[0]) == 0:
            return True

        for sel in selections:
            for line in self.view.lines(sel):
                if line.contains(area):
                    return True

        return False

    def toggle_line(self, edit, area, action):
        text = self.view.substr(area)

        if action == 'comment':
            modified_text = re.sub(r'^(\h*)(.*# debug)\h*$', r'\1# \2', text)

        elif action == 'uncomment':
            modified_text = re.sub(r'^(\h*)# (.*# debug)\h*$', r'\1\2', text)

        self.view.replace(edit, area, modified_text)

    def run(self, edit, action):

        areas_to_comment = self.view.find_all('^(\h*)([^#\n]*# debug)\h*$')
        areas_to_uncomment = self.view.find_all('^(\h*)# (.*# debug)\h*$')

        if action == "comment":
            for area in areas_to_comment[::-1]:
                if self.is_selected(area):
                    self.toggle_line(edit, area, 'comment')

        elif action == "uncomment":
            for area in areas_to_uncomment[::-1]:
                if self.is_selected(area):
                    self.toggle_line(edit, area, 'uncomment')

        elif action == "toggle":
            areas_to_toggle = sorted(areas_to_comment + areas_to_uncomment)
            for area in areas_to_toggle[::-1]:
                if self.is_selected(area):
                    action = 'comment' if area in areas_to_comment else 'uncomment'
                    self.toggle_line(edit, area, action)
