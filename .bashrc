export PATH="/usr/local/opt/tcl-tk/bin:$PATH"
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
source <(fx --comp bash)
eval "$(zoxide init bash)"
