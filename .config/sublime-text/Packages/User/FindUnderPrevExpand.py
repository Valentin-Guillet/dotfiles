
import sublime
import sublime_plugin


class FindUnderPrevExpandCommand(sublime_plugin.TextCommand):

    def run(self, edit, skip=False):
    	
        areas = list(self.view.sel())
        self.view.sel().clear()

        first_area = areas.pop(0) if skip else areas[0]
        self.view.sel().add(first_area)

        self.view.window().run_command('find_under_prev')
        self.view.sel().add_all(areas)
