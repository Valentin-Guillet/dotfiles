import sublime
import sublime_plugin
import re


class DebugCommand(sublime_plugin.TextCommand):

    def run(self, edit, action):

        if hasattr(self, action):
            getattr(self, action)(edit)

    def toggle(self, edit):

        selections = list(self.view.sel())[::-1]
        lines = []
        for sel in selections:
            for line in self.view.lines(sel)[::-1]:
                if line not in lines:
                    lines.append(line)

        for line in lines:
            text = self.view.substr(line)
            if text:
                if re.match(r'^.*\s*# debug\s*$', text):
                    modified_text = re.sub(r'^(.*?)\s*# debug\s*$', r'\1', text)
                else:
                    modified_text = text + '        # debug'
                self.view.replace(edit, line, modified_text)
        sublime.status_message(str(len(lines)) + " lines toggled")

    def remove(self, edit):

        selections = list(self.view.sel())

        # If no specific area is selected, select every line with '# debug'
        if not selections or (len(selections) == 1 and len(selections[0]) == 0):
            lines = self.view.find_all(r'^.*# debug\h*\n')

        # Else, select only the lines within the selections
        else:
            lines = []
            for sel in selections:
                for line in self.view.lines(sel):
                    line = self.view.full_line(line)  # selects also the trailing newline character
                    text = self.view.substr(line)
                    match = re.match(r'^.*# debug\h*\n', text)

                    if match and line not in lines:
                        lines.append(line)

        for line in lines[::-1]:
            self.view.erase(edit, line)
        sublime.status_message(str(len(lines)) + " lines removed")

    def comment(self, edit):
        areas_to_comment, _ = self._get_debug_areas(edit)
        for area in areas_to_comment[::-1]:
            self._toggle_line(edit, area, 'comment')
        sublime.status_message(str(len(areas_to_comment)) + " debug lines commented")

    def uncomment(self, edit):
        _, areas_to_uncomment = self._get_debug_areas(edit)
        for area in areas_to_uncomment[::-1]:
            self._toggle_line(edit, area, 'uncomment')
        sublime.status_message(str(len(areas_to_uncomment)) + " debug lines uncommented")

    def toggle_comment(self, edit):
        areas_to_comment, areas_to_uncomment = self._get_debug_areas(edit)
        areas_to_toggle = sorted(areas_to_comment + areas_to_uncomment)
        for area in areas_to_toggle[::-1]:
            action = 'comment' if area in areas_to_comment else 'uncomment'
            self._toggle_line(edit, area, action)
        sublime.status_message(str(len(areas_to_toggle)) + " debug lines toggled")

    def _get_debug_areas(self, edit):
        selections = list(self.view.sel())

        # If no specific area is selected, select every line with '# debug'
        if not selections or (len(selections) == 1 and len(selections[0]) == 0):
            areas_to_comment = self.view.find_all(r'^([ \t]*)([^#\n]*# debug)[ \t]*$')
            areas_to_uncomment = self.view.find_all(r'^([ \t]*)# (.*# debug)[ \t]*$')

        # Else, select only the lines within the selections
        else:
            areas_to_comment = []
            areas_to_uncomment = []
            for sel in selections:
                for line in self.view.lines(sel):
                    text = self.view.substr(line)

                    # Must the line be commented...
                    match_comment = re.match(r'^([ \t]*)([^#\n]*# debug)[ \t]*$', text)
                    if match_comment and line not in areas_to_comment:
                        areas_to_comment.append(line)

                    # ...or uncommented ?
                    match_uncomment = re.match(r'^([ \t]*)# (.*# debug)[ \t]*$', text)
                    if match_uncomment and line not in areas_to_uncomment:
                        areas_to_uncomment.append(line)

        return areas_to_comment, areas_to_uncomment

    def _toggle_line(self, edit, area, action):
        text = self.view.substr(area)

        if action == 'comment':
            modified_text = re.sub(r'^([ \t]*)(.*# debug)[ \t]*$', r'\1# \2', text)

        elif action == 'uncomment':
            modified_text = re.sub(r'^([ \t]*)# (.*# debug)[ \t]*$', r'\1\2', text)

        self.view.replace(edit, area, modified_text)
