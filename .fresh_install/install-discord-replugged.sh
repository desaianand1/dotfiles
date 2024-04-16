#!/bin/bash

INSTALLER="replugged-installer-macos.app.tar.gz"
DOWNLOAD_URL="https://github.com/replugged-org/tauri-installer/releases/latest/download/$INSTALLER"

# Install Discord Replugged
echo "Installing Discord Replugged..."
curl -O $DOWNLOAD_URL

# Extract tar zip
tar -xzf $INSTALLER
APP_FILE=$(ls | grep '^Replugged.\*.app$')

# Install App
cp $APP_FILE /Applications/
echo "✨Done! Discord Replugged installed!"
