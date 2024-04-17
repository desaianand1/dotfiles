export PATH="/usr/local/opt/tcl-tk/bin:$PATH"
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
source <(fx --comp bash)
eval "$(zoxide init bash --cmd cd)"

source "${HOME}/.zgenom/zgenom.zsh"

# Check for updates every 7 days
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

