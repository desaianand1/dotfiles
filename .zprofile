# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Load SSH keys from macOS Keychain into agent
ssh-add --apple-load-keychain 2>/dev/null

# pyenv
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"
fi
if command -v pyenv-virtualenv-init > /dev/null 2>&1; then
    eval "$(pyenv virtualenv-init -)"
fi

# rbenv
if command -v rbenv 1>/dev/null 2>&1; then
    eval "$(rbenv init - zsh)"
fi
