export EDITOR="nvim"
export PATH="/usr/local/opt/tcl-tk/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export JAVA_HOME=/opt/homebrew/opt/openjdk
export PATH="$PATH:$HOME/.spicetify"
export NVM_DIR="$HOME/.nvm"
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
export PATH=$HOME/Developer/flutter/bin:$PATH
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH":"$HOME/.pub-cache/bin"
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
export PATH="$PATH:$HOME/.local/bin"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
