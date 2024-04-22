# dotfiles
miscellanous .dotfiles, and setup automation to get a new macOS machine up and running with minimal labor

## Overview
TODO: Add system screenshot
### System
- 💻 Terminal: kitty
- 🐚 Shell: zsh (& zgenom for some plugin management)
- ✍️ Font: JetBrains Nerd Font Mono (primarily; Fira Code Mono, Mononoki among others)
- 📝 Code Editor: Neovim or VSCode depending on the mood and language.
- 📝 Note Editor: Obsidian, rarely Typora.
- 💬 Prompt: p10k
- 🪟 Window Manager: xQuartz + Rectangle (@Apple how is this not a native feature)

### 🎨 Themes
TODO: add theme screenshot
- Catppuccin Macchiato (Primary)
- Everforest Dark
- Tokyo Night Storm
- (Atom) One Dark Pro
- Rose Pine Moon
- ... a few others I rotate through

Everything has been themed from kitty, Neovim, Firefox to Alfred, Discord, Spotify, Obsidian and even Bitwarden, zsh-fast-syntax-highlighting, k9s, bat, fx and matplotlib using these palettes.
I've wasted way too much time on this.

### Terminal niceties

- zoxide (aliased to `cd`): Makes it sooo convenient to jump around far directories without spamming `ls` to figure out paths or cycling zsh history. Great tool!
- fzf: Fuzzy search to find anything, anywhere with an intuitive terminal interface. Great for cherry picking.
- eza (aliased to `ls`): Makes traditional `ls` output prettier and more structured. Has neat metadata, NF icons, sorting options and flags.
- fx: interactive JSON viewer and processor. Powerful features to process and manipulate JSON or YAML files right in the terminal. Works great with `jq`
- k9s: Splendid Kubernetes client, right in your terminal. Free, OSS and themeable. Octant or Lens could never.
- tldr: provides brief `man` excerpts and usecases for my simple, monkey brain. Very useful for daunting commands.
- thefuck: aides my clumsy fingers. Auto-fixes broken commands or typos by executing the correct intention when you type `fuck`. Pretty carthatic at times.
- howdoi: solves those split-second "how do I exit vim again?" moments right in the terminal. Saves a trip to the browser/stackoverflow
- commitizen: interactive helper tool to create [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## Installation

TODO: replicate install steps


## ✏️ Credits

A lot of my dotfile management process and conventions are heavily borrowed from widely available templates and work found online [^1][^2][^3][^4]

## Citations

[^1]: https://wiki.archlinux.org/title/Dotfiles
[^2]: https://news.ycombinator.com/item?id=11071754
[^3]: https://medium.com/@todariasova/managing-your-dotfiles-59e13e8ab2d
[^4]: https://www.atlassian.com/git/tutorials/dotfiles



