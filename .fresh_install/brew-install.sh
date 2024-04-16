#!/bin/bash

# Install Homebrew
echo "🍺Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew update

# Homebrew Taps

brew tap homebrew/cask-versions
brew tap homebrew/cask-fonts

# Install apps and casks
echo "🍻Fetching all your brews!"
xargs brew install < .brew-list
echo "🍻Fetching all your casked brews!"
xargs brew install --cask < .brew-cask-list
echo "✨Done! Homebrew is installed and brewed!"
