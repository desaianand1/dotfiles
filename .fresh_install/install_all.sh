#!/bin/bash

set -eo pipefail

scripts=(
    "install_homebrew.sh"
    "install_zgenom.sh"
    "install_kitty.sh"
    "install_discord_replugged.sh"
    "install_readarr.sh"
    "install_spicetify_marketplace.sh"
)

for script in "${scripts[@]}"; do
    echo "Running $script..."
    if bash "$HOME/.fresh_install/$script"; then
        echo "$script completed successfully."
    else
        echo "Error: $script failed. Check individual script files for details."
    fi
done

echo "✅ All installation scripts have been run!"
