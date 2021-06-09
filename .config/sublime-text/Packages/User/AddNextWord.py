import sublime
import sublime_plugin
from collections import defaultdict


class AddNextWordCommand(sublime_plugin.TextCommand):

    def compute_line(self, skip):
        areas = list(self.view.sel())

        self.view.sel().clear()
        self.view.sel().add(areas[-1])
        if skip:
            areas.pop(-1)

        valid = False
        pos, last_pos = 0, 1
        while not valid and pos != last_pos:
            self.view.run_command('move', {"by": "word_ends", "forward": True})
            self.view.run_command('expand_selection', {"to": "word"})

            selection = self.view.sel()[-1]
            last_pos = pos
            pos = (selection.a, selection.b)

            valid = any([c.isalnum() for c in self.view.substr(selection)])

        if not valid:
            self.view.sel().clear()

        return areas + list(self.view.sel())

    def run(self, edit, skip=False):
        areas = list(self.view.sel())

        lines = defaultdict(list)
        for area in areas:
            line = self.view.line(area)
            lines[(line.a, line.b)].append(area)

        new_areas = []
        for areas in lines.values():
            self.view.sel().clear()
            self.view.sel().add_all(areas)
            new_areas.extend(self.compute_line(skip))

        self.view.sel().clear()
        self.view.sel().add_all(new_areas)
