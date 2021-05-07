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

            opening_chars = {'(': ')', '[': ']', '{': '}'}
            closing_chars = {')': 0, ']': 0, '}': 0}
            nb_brackets = 0
            for index in range(len(prev_line)-1, -1, -1):
                if prev_line[index] in closing_chars:
                    closing_chars[prev_line[index]] -= 1

                elif prev_line[index] in opening_chars:
                    opening_char = opening_chars[prev_line[index]]
                    closing_chars[opening_char] += 1

                if any(filter(lambda v: v > 0, closing_chars.values())):
                    break

            else:
                continue

            index_first_char = len(text) - len(text.lstrip())
            spaces = ' ' * (index - index_first_char + 1)
            self.view.insert(edit, line.a, spaces)
