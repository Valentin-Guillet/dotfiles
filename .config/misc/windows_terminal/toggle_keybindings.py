#!/usr/bin/env python3

import json
import shutil
import subprocess
from pathlib import Path


def get_settings_path():
    win_path_file = Path.home() / ".cache" / "bash" / "winterm_settings_path"

    # Settings path already saved in cache
    if win_path_file.exists():
        with win_path_file.open() as file:
            return Path(file.read())

    local_app_data = subprocess.check_output(["wslvar", "LOCALAPPDATA"])
    settings_path = subprocess.check_output(["wslpath", local_app_data]).decode().strip()
    settings_file = (
        Path(settings_path) / "Packages" / "Microsoft.WindowsTerminal_8wekyb3d8bbwe" / "LocalState" / "settings.json"
    )

    with win_path_file.open("w") as file:
        file.write(str(settings_file))

    return settings_file

def get_custom_settings():
    local_settings_path = Path(__file__).with_name("settings.json")
    with local_settings_path.open() as file:
        return json.load(file)

def main():
    settings_file = get_settings_path()
    settings_file_bak = settings_file.with_suffix(".json.bak")

    # Reactivate
    if settings_file_bak.exists():
        shutil.move(settings_file_bak, settings_file)
        return

    # Deactivate
    with settings_file.open() as file:
        old_settings = json.load(file)

    new_settings = old_settings.copy()
    new_settings["actions"] = [obj for obj in new_settings["actions"] if not obj.get("toggle", False)]

    # If we want to deactivate but no "toggle" has been found, this means that the
    # settings file has been overwritten by WindowsTerminal, so we get all
    # keybindings from `settings.json` again
    if len(new_settings["actions"]) == len(old_settings["actions"]):
        custom_settings = get_custom_settings()

        old_settings["actions"] = custom_settings["actions"]
        new_settings["actions"] = [obj for obj in custom_settings["actions"] if not obj.get("toggle", False)]

    # Save old settings in backup file to reactivate later
    with settings_file_bak.open("w") as file:
        json.dump(old_settings, file, indent=4)

    with settings_file.open("w") as file:
        json.dump(new_settings, file, indent=4)


if __name__ == "__main__":
    main()
