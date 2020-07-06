#!/bin/bash

mkdir backup

while read file
do
    mkdir -p backup/$(dirname "$file")
    if [ -f "$file" ]
    then
        cp "$file" backup/
    elif [ -d "$file" ]
    then
        cp -r "$file" backup/
    fi
done < <(sed -e "/^\s*#.*$/d" -e "/^\s*$/d" list_files)

sed -i "s;^\(\s\+\)export CONFIG_DIR=.*;\1export CONFIG_DIR=$(realpath .);" toggle_config

echo "Create a symbolic link in a directory from PATH to $(realpath toggle_config)"
echo "For instance :"
echo "    ln -s $(realpath toggle_config) ~/.local/bin/val"

