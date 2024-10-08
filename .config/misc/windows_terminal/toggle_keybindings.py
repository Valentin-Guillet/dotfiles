#!/usr/bin/env python3

import json
import shutil
import subprocess
from pathlib import Path


def main():
    win_path_file = Path.home() / ".cache" / "bash" / "winterm_settings_path"
    if not win_path_file.exists():
        local_app_data = subprocess.check_output(["wslvar", "LOCALAPPDATA"])
        settings_path = subprocess.check_output(["wslpath", local_app_data]).decode().strip()
        settings_file = (
            Path(settings_path)
            / "Packages"
            / "Microsoft.WindowsTerminal_8wekyb3d8bbwe"
            / "LocalState"
            / "settings.json"
        )

        with win_path_file.open("w") as file:
            file.write(str(settings_file))
    else:
        with win_path_file.open() as file:
            settings_file = Path(file.read())

    settings_file_bak = settings_file.with_suffix(".json.bak")

    # Deactivate
    if not settings_file_bak.exists():
        shutil.copy2(settings_file, settings_file_bak)
        with settings_file_bak.open() as file:
            data = json.load(file)

        data["actions"] = [obj for obj in data["actions"] if not obj.get("toggle", False)]

        with settings_file.open("w") as file:
            json.dump(data, file, indent=4)

    # Reactivate
    else:
        shutil.move(settings_file_bak, settings_file)


if __name__ == "__main__":
    main()
