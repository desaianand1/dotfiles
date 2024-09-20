#!/bin/bash

set -eo pipefail  # Exit on error and pipe failure

LOCAL_WORKTREE_REPO="$HOME/dotfiles"
GITHUB_REMOTE='git@github.com:desaianand1/dotfiles.git'
GITHUB_HTTPS_REMOTE='https://github.com/desaianand1/dotfiles.git'
ALIAS_NAME='dotfiles'
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Check for command line tools
check_prerequisites() {
    if ! command -v git >/dev/null 2>&1; then
        echo "Git is not installed. Installing Git..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            xcode-select --install
        elif command -v apt-get >/dev/null 2>&1; then
            # Debian/Ubuntu
            sudo apt-get update && sudo apt-get install -y git
        elif command -v yum >/dev/null 2>&1; then
            # CentOS/RHEL
            sudo yum install -y git
        else
            echo "Unable to install Git automatically. Please install Git and run this script again."
            exit 1
        fi
    fi
}

# Backup existing dotfiles
backup_existing_files() {
    echo "🗃️ Backing up existing dotfiles to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    local files_to_checkout=$(git --git-dir="$LOCAL_WORKTREE_REPO" --work-tree="$HOME" ls-tree -r main --name-only 2>/dev/null || echo "")
    
    for file in $files_to_checkout; do
        if [[ -e "$HOME/$file" && ! -L "$HOME/$file" ]]; then
            mkdir -p "$(dirname "$BACKUP_DIR/$file")"
            mv "$HOME/$file" "$BACKUP_DIR/$file"
            echo "Backed up: $file"
        fi
    done
}

# Setup dotfiles
setup_dotfiles() {
    local remote_url="$1"
    if [ -d "$LOCAL_WORKTREE_REPO" ]; then
        echo "The dotfiles repository already exists at $LOCAL_WORKTREE_REPO"
        read -p "Do you want to delete it and clone again? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$LOCAL_WORKTREE_REPO"
        else
            echo "Exiting without making changes."
            exit 1
        fi
    fi

    echo "Cloning dotfiles GitHub repo..."
    git clone --bare "$remote_url" "$LOCAL_WORKTREE_REPO"

    # Define the dotfiles function
    dotfiles() {
        git --git-dir="$LOCAL_WORKTREE_REPO" --work-tree="$HOME" "$@"
    }

    # Backup existing files
    backup_existing_files

    echo "Checking out dotfiles..."
    dotfiles checkout
    if [ $? -ne 0 ]; then
        echo "Checkout failed. Your existing files may have prevented the checkout."
        echo "Please review the errors above, move any conflicting files, and run the script again."
        exit 1
    fi

    echo "Setting up git configurations..."
    dotfiles config status.showUntrackedFiles no
    dotfiles config core.worktree "$HOME"

    # Add dotfiles directory to .gitignore
    echo "dotfiles" >> "$HOME/.gitignore"
    dotfiles add "$HOME/.gitignore"
    dotfiles commit -m "Add dotfiles to .gitignore"

    # Add alias to zsh configuration file
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "alias $ALIAS_NAME" "$HOME/.zshrc"; then
            echo "alias $ALIAS_NAME='git --git-dir=$LOCAL_WORKTREE_REPO --work-tree=$HOME'" >> "$HOME/.zshrc"
            echo "Added $ALIAS_NAME alias to .zshrc"
        fi
    else
        echo "Warning: .zshrc not found. You may need to manually add the dotfiles alias to your shell configuration."
    fi
}

# macOS-specific setup
macos_setup() {
    # Install Homebrew if not already installed
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Install macOS command line tools if not already installed
    if ! xcode-select -p >/dev/null 2>&1; then
        echo "Installing macOS command line tools..."
        xcode-select --install
    fi
}

# Main execution
main() {
    echo "This script will set up your dotfiles repository."
    echo "It will clone the repository, backup existing files, and set up the necessary configurations."
    
    check_prerequisites

    if [[ "$OSTYPE" == "darwin"* ]]; then
        macos_setup
    fi

    read -p "Do you want to use SSH for cloning? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ! ssh -T git@github.com &>/dev/null; then
            echo "SSH connection to GitHub failed. Please set up your SSH key with GitHub and try again."
            echo "For instructions, visit: https://docs.github.com/en/authentication/connecting-to-github-with-ssh"
            exit 1
        fi
        remote_url="$GITHUB_REMOTE"
    else
        remote_url="$GITHUB_HTTPS_REMOTE"
    fi

    read -p "Do you want to proceed with the dotfiles setup? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_dotfiles "$remote_url"
        echo "✅ Dotfiles setup complete!"
        echo "🔄 Please restart your shell or source your .zshrc file to use the new alias."
        echo "You can now use the '$ALIAS_NAME' command to manage your dotfiles."
    else
        echo "❌ Setup cancelled."
    fi
}

main
