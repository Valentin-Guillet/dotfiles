#!/usr/bin/env -S python3 -B

import json

from toggle_keybindings import get_custom_settings, get_settings_path


def main():
    settings_file = get_settings_path()

    with settings_file.open() as file:
        settings = json.load(file)

    custom_settings = get_custom_settings()
    settings.update(custom_settings)

    with settings_file.open("w") as file:
        json.dump(settings, file, indent=4)


if __name__ == "__main__":
    main()
