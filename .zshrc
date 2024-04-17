# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export EDITOR="nvim"
export PATH="/usr/local/opt/tcl-tk/bin:$PATH"
export PATH=$PATH:/Users/anand/.spicetify

eval $(thefuck --alias)
source <(fx --comp zsh)
eval "$(zoxide init zsh --cmd cd)"
eval "$(fzf --zsh)"

source $HOME/.zsh_aliases

source "${HOME}/.zgenom/zgenom.zsh"

# check for updates ever 7 days
zgenom autoupdate

# if the zgenom init script doesn't exist
if ! zgenom saved; then
	# specify plugins here
	zgenom ohmyzsh plugins/git
	zgenom ohmyzsh plugins/gitignore
	zgenom ohmyzsh --completion plugins/kubectl
	zgenom load romkatv/powerlevel10k powerlevel10k
	zgenom load zdharma-continuum/fast-syntax-highlighting
	zgenom load zsh-users/zsh-completions
	zgenom load zsh-users/zsh-autosuggestions
	
	# generate the init script from plugins above
	zgenom save
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
