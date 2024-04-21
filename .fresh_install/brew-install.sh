#!/bin/bash

# Install Homebrew
echo "🍺Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew update

# Install apps and casks
echo "🍻Fetching all your brews, casks and mac App Store apps!"
brew bundle --file=~/.config/brew/Brewfile
echo "✨Done! Homebrew is installed and brewed!"
