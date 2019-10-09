import sublime
import sublime_plugin


class MoveFileInNewTabCommand(sublime_plugin.WindowCommand):
    def run(self, clone):

        if self.window.num_groups() == 1:
            self.window.run_command("set_layout",
                                    {
                                        "cols": [0.0, 0.5, 1.0],
                                        "rows": [0.0, 1.0],
                                        "cells": [[0, 0, 1, 1], [1, 0, 2, 1]]
                                    })

            self.window.run_command("focus_group", {"group": 0})

        if clone:
            initial_group = self.window.active_group()
            self.window.run_command("clone_file")

        if self.window.active_group() == self.window.num_groups()-1:
            target_group = self.window.active_group() - 1
        else:
            target_group = self.window.active_group() + 1

        self.window.run_command("move_to_group", {"group": target_group})

        if clone:
            self.window.run_command("focus_group", {"group": initial_group})
