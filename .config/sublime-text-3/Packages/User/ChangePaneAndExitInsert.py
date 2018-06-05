import sublime
import sublime_plugin


class ChangePaneAndExitInsertCommand(sublime_plugin.TextCommand):
	def run(self, edit, forward=True):

		if forward:
			self.view.window().run_command('next_view')
		else:
			self.view.window().run_command('prev_view')

		self.view.window().run_command('exit_insert_mode')
