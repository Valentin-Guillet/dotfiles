import sublime
import sublime_plugin


class RemoveClosingBracket(sublime_plugin.TextCommand):

    def run(self, edit):

        for index in range(len(self.view.sel())):

            curr_point = self.view.sel()[index]

            whole_region = sublime.Region(0, self.view.size())
            text = self.view.substr(whole_region)
            sign = text[curr_point.begin()-1]

            close_sign = sign.translate(str.maketrans('([{', ')]}'))

            try:
                i = curr_point.begin()
                nb_brackets = 1

                while nb_brackets > 0:
                    if text[i] == sign:
                        nb_brackets += 1
                    elif text[i] == close_sign:
                        nb_brackets -= 1
                    i += 1

                region = sublime.Region(i-1, i)
                self.view.erase(edit, region)

            except (ValueError, IndexError):
                pass

            region = sublime.Region(curr_point.begin()-1, curr_point.begin())
            self.view.erase(edit, region)
