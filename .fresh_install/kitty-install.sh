#!/bin/bash

# Install's kitty terminal
# See installation instructions here in case they changed: https://sw.kovidgoyal.net/kitty/binary/
echo "Installing kitty..."
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
echo "Installing kitty themes..."
# Install all the kitty themes available
# Use `kitten themes` to interactively select one (modifies kitty.conf)
git clone --depth 1 https://github.com/dexpota/kitty-themes.git ~/.config/kitty/kitty-themes
echo "✨Done! kitty installed!"
