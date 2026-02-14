#!/usr/bin/env bash
set -e

# --sync / -s: skip installs, only update submodules and create symlinks
# --force: overwrite ~/.config/nvim even if it looks like a real config (use with caution)
SYNC_ONLY=false
FORCE=false
for arg in "$@"; do
  case "$arg" in
    --sync|-s) SYNC_ONLY=true ;;
    --force|-f) FORCE=true ;;
  esac
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

# CRITICAL: If ~/.config/nvim exists as a directory, ln creates the link *inside* it
# (e.g. ~/.config/nvim/nvim) instead of replacing it. Remove the dir first.
# Safety: don't rm a dir that looks like a real config (init.lua at top) unless --force
if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  if [ -f "$HOME/.config/nvim/init.lua" ] && [ "$FORCE" != true ]; then
    echo "Error: ~/.config/nvim looks like a real config (has init.lua). Refusing to overwrite."
    echo "If this is your dotfiles-managed machine, use: ./install.sh --force"
    exit 1
  fi
  rm -rf "$HOME/.config/nvim"
fi
ln -sfn "$HOME/dotfiles/.config/nvim" "$HOME/.config/nvim"

echo "Installation complete!"
echo "Restart your shell or run: exec zsh"

