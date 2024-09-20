#!/bin/bash

set -eo pipefail

KITTY_INSTALL_DIR="$HOME/.local/kitty.app"
KITTY_THEMES_DIR="$HOME/.config/kitty/kitty-themes"

install_kitty() {
    if [ -d "$KITTY_INSTALL_DIR" ]; then
        echo "kitty is already installed. Updating..."
        "$KITTY_INSTALL_DIR/bin/kitty" +update
    else
        echo "Installing kitty..."
        curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    fi
}

install_kitty_themes() {
    if [ -d "$KITTY_THEMES_DIR" ]; then
        echo "kitty themes are already installed. Updating..."
        cd "$KITTY_THEMES_DIR" && git pull
    else
        echo "Installing kitty themes..."
        git clone --depth 1 https://github.com/dexpota/kitty-themes.git "$KITTY_THEMES_DIR"
    fi
}

echo "Starting kitty installation..."
install_kitty
install_kitty_themes
echo "✅ kitty installation completed."
echo "🎨 Use 'kitten themes' to interactively select a theme (modifies kitty.conf)."

