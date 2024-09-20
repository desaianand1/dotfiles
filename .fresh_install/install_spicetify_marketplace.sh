#!/bin/bash

set -eo pipefail

SPICETIFY_CONFIG_DIR="$HOME/.config/spicetify"

install_spicetify_marketplace() {
    if [ -d "$SPICETIFY_CONFIG_DIR/CustomApps/marketplace" ]; then
        echo "Spicetify Marketplace is already installed. Updating..."
        curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.sh | sh
    else
        echo "Installing Spicetify Marketplace..."
        curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.sh | sh
    fi
}

echo "Starting Spicetify Marketplace installation..."
install_spicetify_marketplace
echo "✅ Spicetify Marketplace installation completed."

