# Run terminal dashboard
source "${HOME}/.config/zsh/dashboard.zsh"

# Enable Powerlevel10k instant prompt
# Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load zgenom
source "${HOME}/.zgenom/zgenom.zsh"
zgenom autoupdate

# zgenom configuration
if ! zgenom saved; then
    # Your zgenom plugin configuration here
    zgenom ohmyzsh plugins/git
    zgenom ohmyzsh plugins/gitignore
    zgenom ohmyzsh --completion plugins/kubectl
    zgenom load "MichaelAquilina/zsh-you-should-use"
    zgenom load romkatv/powerlevel10k powerlevel10k
    zgenom load zdharma-continuum/fast-syntax-highlighting
    zgenom load zsh-users/zsh-completions
    zgenom load zsh-users/zsh-autosuggestions	
    zgenom save
fi

# Lazy-load version managers (pyenv, nvm, rbenv)
source "${HOME}/.config/zsh/lazy-load.zsh"

# Load aliases
source $HOME/.zsh_aliases

# Tool integrations
eval $(thefuck --alias)
source <(fx --comp zsh)
eval "$(zoxide init zsh --cmd cd)"
eval "$(fzf --zsh)"
source "${HOME}/.config/fzf/fzf-git.sh"
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"
command -v navi &>/dev/null && eval "$(navi widget zsh)"

# fzf catppuccin macchiato theme
export FZF_DEFAULT_OPTS=" \
--color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
--color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
--color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796"

# Ignore Doppler CLI secrets from being stored in history
HISTORY_IGNORE="(doppler secrets set*)"

# Load Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Auto-start zellij (attach to existing session or create new one)
if command -v zellij &>/dev/null && [[ -z "$ZELLIJ" ]]; then
  zellij attach --create default
fi

