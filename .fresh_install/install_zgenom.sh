#!/bin/bash

set -eo pipefail

ZGENOM_DIR="${HOME}/.zgenom"

install_zgenom() {
    if [ -d "$ZGENOM_DIR" ]; then
        echo "zgenom is already installed. Updating..."
        cd "$ZGENOM_DIR" && git pull
    else
        echo "🇿 Installing zgenom..."
        git clone https://github.com/jandamm/zgenom.git "$ZGENOM_DIR"
    fi
}

configure_zgenom() {
    local ZGENOM_SRC="source '${ZGENOM_DIR}/zgenom.zsh'"
    local ZGENOM_PLUGINS="
# if the zgenom init script doesn't exist
if ! zgenom saved; then
  # specify plugins here
    zgenom ohmyzsh plugins/git
    zgenom ohmyzsh plugins/gitignore
    zgenom ohmyzsh --completion plugins/kubectl
    zgenom load "MichaelAquilina/zsh-you-should-use"
    zgenom load romkatv/powerlevel10k powerlevel10k
    zgenom load zdharma-continuum/fast-syntax-highlighting
    zgenom load zsh-users/zsh-completions
    zgenom load zsh-users/zsh-autosuggestions
  # generate the init script from plugins above
    zgenom save
fi
"
    local RC_FILE="$HOME/.zshrc"
    if [ -f "$RC_FILE" ]; then
        if ! grep -q "$ZGENOM_SRC" "$RC_FILE"; then
            echo "$ZGENOM_SRC" >> "$RC_FILE"
            echo "$ZGENOM_PLUGINS" >> "$RC_FILE"
            echo "Added zgenom configuration to $RC_FILE"
        else
            echo "zgenom configuration already exists in $RC_FILE"
        fi
    fi
}

echo "Starting zgenom installation and configuration..."
install_zgenom
configure_zgenom
echo "✅ zgenom installation and configuration completed."

