#!/bin/bash

INSTALLER="Readarr.*.zip"
DOWNLOAD_URL="https://readarr.servarr.com/v1/update/develop/updatefile?os=osx&runtime=netcore&arch=arm64&installer=true"

# Install Readarr
echo "Installing Readarr..."
curl -O $DOWNLOAD_URL

# Extract tar zip
tar -xzf $INSTALLER

# Sign the application
APP_FILE=Readarr.app
codesign --force --deep -s - $APP_FILE

# Install App
cp $APP_FILE /Applications/

echo "✨Done! Readarr installed!"
