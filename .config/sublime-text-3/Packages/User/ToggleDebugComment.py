import sublime
import sublime_plugin
import re


class ToggleDebugCommentCommand(sublime_plugin.TextCommand):

    def run(self, edit, action):

        selections = list(self.view.sel())

        # If no specific area is selected, select every line with '# debug'
        if not selections or (len(selections) == 1 and len(selections[0]) == 0):
            areas_to_comment = self.view.find_all(r'^(\h*)([^#\n]*# debug)\h*$')
            areas_to_uncomment = self.view.find_all(r'^(\h*)# (.*# debug)\h*$')

        # Else, select only the lines within the selections
        else:
            areas_to_comment = []
            areas_to_uncomment = []
            for sel in selections:
                for line in self.view.lines(sel):
                    text = self.view.substr(line)

                    # Must the line be commented...
                    match_comment = re.match(r'^(\h*)([^#\n]*# debug)\h*$', text)
                    if match_comment and line not in areas_to_comment:
                        areas_to_comment.append(line)

                    # ...or uncommented ?
                    match_uncomment = re.match(r'^(\h*)# (.*# debug)\h*$', text)
                    if match_uncomment and line not in areas_to_uncomment:
                        areas_to_uncomment.append(line)

        if action == "comment":
            for area in areas_to_comment[::-1]:
                self.toggle_line(edit, area, 'comment')

        elif action == "uncomment":
            for area in areas_to_uncomment[::-1]:
                self.toggle_line(edit, area, 'uncomment')

        elif action == "toggle":
            areas_to_toggle = sorted(areas_to_comment + areas_to_uncomment)
            for area in areas_to_toggle[::-1]:
                action = 'comment' if area in areas_to_comment else 'uncomment'
                self.toggle_line(edit, area, action)

    def toggle_line(self, edit, area, action):
        text = self.view.substr(area)

        if action == 'comment':
            modified_text = re.sub(r'^(\h*)(.*# debug)\h*$', r'\1# \2', text)

        elif action == 'uncomment':
            modified_text = re.sub(r'^(\h*)# (.*# debug)\h*$', r'\1\2', text)

        self.view.replace(edit, area, modified_text)
