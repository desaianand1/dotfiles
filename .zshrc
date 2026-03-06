# Enable Powerlevel10k instant prompt (must be near top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load zgenom
source "${HOME}/.zgenom/zgenom.zsh"
zgenom autoupdate

# zgenom configuration
if ! zgenom saved; then
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
source "$HOME/.zsh_aliases"

# Tool integrations (lazy-load thefuck to avoid startup cost)
fuck() { unfunction fuck; eval $(thefuck --alias); fuck "$@"; }
# Cache fx completions (regenerate only when fx binary changes)
_fx_comp_cache="${XDG_CACHE_HOME:-$HOME/.cache}/fx-comp.zsh"
if [[ ! -f "$_fx_comp_cache" ]] || [[ "$(command -v fx)" -nt "$_fx_comp_cache" ]]; then
  fx --comp zsh > "$_fx_comp_cache" 2>/dev/null
fi
[[ -f "$_fx_comp_cache" ]] && source "$_fx_comp_cache"

eval "$(zoxide init zsh --cmd cd)"
eval "$(fzf --zsh)"
source "${HOME}/.config/fzf/fzf-git.sh"
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"
command -v navi &>/dev/null && eval "$(navi widget zsh)"
command -v atuin &>/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

# fzf catppuccin macchiato theme
export FZF_DEFAULT_OPTS=" \
--color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
--color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
--color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796"

# History
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE HIST_VERIFY SHARE_HISTORY
HISTORY_IGNORE="(doppler secrets set*)"

# Shell options
setopt AUTO_CD

# Completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Load Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Run terminal dashboard
source "${HOME}/.config/zsh/dashboard.zsh"

# Auto-start zellij (attach to existing session or create new one)
if command -v zellij &>/dev/null && [[ -z "$ZELLIJ" ]]; then
  zellij attach --create default
fi

