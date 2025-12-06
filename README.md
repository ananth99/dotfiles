# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's Included

- **emacs** - Literate Emacs config (config.org → init.el) with Elpaca, LSP, Magit, Vertico, etc.
- **ghostty** - Ghostty terminal config optimized for Emacs keybindings

## Prerequisites

### macOS

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install GNU Stow
brew install stow

# Install Emacs 30 with native compilation
brew tap d12frosted/emacs-plus
brew install emacs-plus@30 --with-native-comp

# Install Ghostty
brew install --cask ghostty

# Install JetBrains Mono font
brew install --cask font-jetbrains-mono

# Install dev tools (required by Emacs config)
brew install ripgrep fd prettier
npm install -g typescript-language-server
```

## Installation

```bash
# Clone the repo
git clone git@github.com:YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Stow packages (creates symlinks to ~/.config/)
stow emacs
stow ghostty
```

## Post-Installation

### Emacs

1. Launch Emacs
2. Wait for Elpaca to bootstrap and install all packages (first launch takes a few minutes)
3. Restart Emacs

### Making Changes

Edit `config.org`, then tangle with `C-c C-v C-t` and restart Emacs.

## Unstowing

To remove symlinks:

```bash
stow -D emacs
stow -D ghostty
```
