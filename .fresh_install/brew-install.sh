#!/bin/bash

# Install Homebrew

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew update

# Homebrew Taps

brew tap homebrew/cask-versions
brew tap homebrew/cask-fonts

# Install apps and casks

xargs brew install < .brew-list
xargs brew install --cask < .brew-cask-list
