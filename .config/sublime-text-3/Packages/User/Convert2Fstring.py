import sublime
import sublime_plugin


class ConvertToFstringCommand(sublime_plugin.TextCommand):

    def run(self, edit):

        if not self.view.size():
            return

        whole_region = sublime.Region(0, self.view.size())
        text = self.view.substr(whole_region)

        for index in range(len(self.view.sel())):

            curr_point = self.view.sel()[index]

            i = curr_point.begin() - 1
            while i >= 0 and text[i] != '"' and text[i] != "'" and text[i] != '\n':
                i -= 1

            if i >= 0 and text[i] != '\n':
                self.view.insert(edit, i, 'f')
