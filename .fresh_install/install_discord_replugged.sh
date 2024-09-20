#!/bin/bash

set -eo pipefail

INSTALLER="replugged-installer-macos.app.tar.gz"
DOWNLOAD_URL="https://github.com/replugged-org/tauri-installer/releases/latest/download/$INSTALLER"
INSTALL_DIR="/Applications"

install_discord_replugged() {
    if [ -d "$INSTALL_DIR/Replugged.app" ]; then
        echo "Discord Replugged is already installed. Skipping installation."
        return
    fi

    echo "Downloading Discord Replugged..."
    curl -L -o "$INSTALLER" "$DOWNLOAD_URL"

    echo "Extracting Discord Replugged..."
    tar -xzf "$INSTALLER"

    APP_FILE=$(ls | grep -i '^Replugged.*\.app$')
    if [ -z "$APP_FILE" ]; then
        echo "Error: Replugged app not found in the extracted files."
        exit 1
    fi

    echo "Installing Discord Replugged..."
    mv "$APP_FILE" "$INSTALL_DIR/"

    echo "Cleaning up..."
    rm "$INSTALLER"
}

echo "Starting Discord Replugged installation..."
install_discord_replugged
echo "✅ Discord Replugged installation completed."

