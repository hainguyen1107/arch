#! /bin/bash

# Quit running waybar instances
killall waybar

# Load configuration
waybar -c ~/.config/waybar/config.jsonc
waybar -s ~/.config/waybar/style.css

