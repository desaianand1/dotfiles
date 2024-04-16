#!/bin/bash

# Install zgenom to manage plugins.
# TODO: can I do this on my own? probably, given some time...

# Install zgenom
echo "Installing zgenom"
git clone https://github.com/jandamm/zgenom.git "${HOME}/.zgenom"

# Initialize it for both bash and zsh
echo "Initializing zgenom for bash and zsh..."
ZGENOM_SRC="source '${HOME}/.zgenom/zgenom.zsh'"
echo $ZGENOM_SRC >> ~/.bashrc
echo $ZGENOM_SRC >> ~/.zshrc

# Create the plugin initialization 'zone'
echo "Almost done..."
ZGENOM_PLUGINS="""
# if the zgenom init script doesn't exist
if ! zgenom saved; then

  # specify plugins here

  # generate the init script from plugins above
  zgenom save
fi
"""

echo $ZGENOM_PLUGINS  >> ~/.bashrc
echo $ZGENOM_PLUGINS >> ~/.zshrc
echo "✨Done! zgenom Installed!"
