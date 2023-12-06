#!/bin/bash

mkdir -p backup

./toggle_config backup

echo ""
echo "Create a symbolic link in a directory from PATH to $(realpath toggle_config)"
echo "For instance :"
echo "    ln -s $(realpath toggle_config) ~/.local/bin/config_switch"

