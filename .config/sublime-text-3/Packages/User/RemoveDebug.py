import sublime
import sublime_plugin
import re


class RemoveDebugCommand(sublime_plugin.TextCommand):

    def run(self, edit):

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
