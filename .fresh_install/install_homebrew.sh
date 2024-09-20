#!/bin/bash

set -eo pipefail

install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew is already installed. 🔄 Updating..."
        brew update
    else
        echo "🍺 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

install_packages() {
    echo "🍻 Fetching all your brews, casks and Mac App Store apps!..."
    if [[ -f "$HOME/.config/brew/Brewfile" ]]; then
        brew bundle --file="$HOME/.config/brew/Brewfile" || echo "⚠️ Warning: Some packages failed to install"
    else
        echo "Error: Brewfile not found at $HOME/.config/brew/Brewfile"
        return 1
    fi
}


install_homebrew
install_packages
    
echo "✅ Homebrew is installed and brewed! 🍻"

