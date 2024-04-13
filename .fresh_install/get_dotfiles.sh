# /bin/bash
# Install dotfiles from remote

LOCAL_WORKTREE_REPO=’dotfiles’
GITHUB_REMOTE=’git@github.com:desaianand1/dotfiles.git’
ALIAS_NAME=’dotfiles’

GIT=`/usr/bin/git`if [ ! -d “$HOME/$REPO_NAME” ]; then
 echo “Cloning dotfiles GitHub repo...”
 `git clone --bare $GITHUB_REMOTE $HOME/$LOCAL_WORKTREE_REPO`
 cd ~/
 echo “Adding your $LOCAL_WORKTREE_REPO directory to .gitignore”
 echo “$LOCAL_WORKTREE_REPO” >> .gitignore
 alias dotfiles=’$GIT --git-dir=$HOME/dotfiles/ — work-tree=$HOME’
 echo “Copying your dotfiles to your home directory...”
 `dotfiles checkout`
 echo “Adding $ALIAS_NAME  alias to your bash and zsh config files”
 echo “alias dotfiles=’$GIT --git-dir=$HOME/dotfiles/ --work-tree=$HOME’” >> $HOME/.bashrc
 echo “alias dotfiles=’$GIT --git-dir=$HOME/dotfiles/ --work-tree=$HOME’” >> $HOME/.zshrc
 source $HOME/.bashrc
 echo “Configuring tracking of files..”
 `dotfiles config --local status.showUntrackedFiles no`
 echo “All done!”
else
 echo “You already have a $HOME/$LOCAL_WORKTREE_REPO directory”
fi
