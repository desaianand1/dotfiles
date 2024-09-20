#!/bin/bash

set -eo pipefail

DOWNLOAD_URL="https://readarr.servarr.com/v1/update/develop/updatefile?os=osx&runtime=netcore&arch=arm64&installer=true"
INSTALL_DIR="/Applications"

install_readarr() {
    if [ -d "$INSTALL_DIR/Readarr.app" ]; then
        echo "Readarr is already installed. Skipping installation."
        return
    fi

    echo "Downloading Readarr..."
    curl -L -o "Readarr.zip" "$DOWNLOAD_URL"

    echo "Extracting Readarr..."
    unzip -q "Readarr.zip"

    APP_FILE=$(ls | grep -i '^Readarr.*\.app$')
    if [ -z "$APP_FILE" ]; then
        echo "Error: Readarr app not found in the extracted files."
        exit 1
    fi

    echo "Signing Readarr..."
    codesign --force --deep -s - "$APP_FILE"

    echo "Installing Readarr..."
    mv "$APP_FILE" "$INSTALL_DIR/"

    echo "Cleaning up..."
    rm "Readarr.zip"
}

echo "Starting Readarr installation..."
install_readarr
echo "✅ Readarr installation completed."

