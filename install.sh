#!/usr/bin/env bash
set -e

# --sync / -s: skip installs, only update submodules and create symlinks
SYNC_ONLY=false
for arg in "$@"; do
  case "$arg" in --sync|-s) SYNC_ONLY=true ;; esac
done

if [ "$SYNC_ONLY" = true ]; then
  [ -d "$HOME/dotfiles" ] || { echo "Error: ~/dotfiles not found. Run full install first."; exit 1; }
  echo "Sync mode: updating submodules and symlinks only."
else
  echo "Installing dependencies..."
  sudo apt update
  sudo apt install -y git curl zsh tmux neovim fonts-powerline

  echo "Cloning dotfiles repo with submodules..."
  if [ ! -d "$HOME/dotfiles" ]; then
    git clone --recurse-submodules https://github.com/Gartner24/dotfiles.git "$HOME/dotfiles"
  else
    echo "Dotfiles repo already exists at $HOME/dotfiles"
  fi
fi

cd "$HOME/dotfiles"

if [ "$SYNC_ONLY" = true ]; then
  git pull
fi

echo "Initializing submodules..."
git submodule update --init --recursive

if [ "$SYNC_ONLY" = false ]; then
  echo "Installing Oh My Zsh..."
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    echo "Oh My Zsh already installed."
  fi

  echo "Installing Zsh plugins and theme..."
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" || true
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" || true
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" || true
  git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions" || true
fi

echo "Creating symlinks..."
ln -sf "$HOME/dotfiles/.zshrc" "$HOME/.zshrc"
ln -sf "$HOME/dotfiles/.tmux.conf" "$HOME/.tmux.conf"
mkdir -p "$HOME/.config"

# Nvim: clone if missing, otherwise just git pull (no overwriting)
if [ ! -d "$HOME/.config/nvim/.git" ]; then
  [ -d "$HOME/.config/nvim" ] && { echo "Error: ~/.config/nvim exists but is not a git repo. Refusing to overwrite."; exit 1; }
  echo "Cloning nvim config..."
  git clone https://github.com/Gartner24/nvim.lua.git "$HOME/.config/nvim"
else
  echo "Updating nvim config..."
  (cd "$HOME/.config/nvim" && git fetch && git pull)
fi

echo "Installation complete!"
echo "Restart your shell or run: exec zsh"

