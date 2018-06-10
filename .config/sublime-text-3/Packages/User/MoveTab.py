import sublime
import sublime_plugin


class MoveTabCommand(sublime_plugin.WindowCommand):

	def run(self, forward=True):
		view = self.window.active_view()
		group, index = self.window.get_view_index(view)
		nb_total_tab = len(self.window.views_in_group(group))

		# If no tab is open
		if index < 0:
			return

		if forward:
			position = (index + 1) % nb_total_tab
		else:
			position = (index - 1) % nb_total_tab

		# Avoid flashing tab when moving to same index
		if position == index:
			return

		self.window.set_view_index(view, group, position)
		self.window.focus_view(view)
