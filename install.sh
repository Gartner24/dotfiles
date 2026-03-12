#!/usr/bin/env bash
set -e

# --sync / -s: skip installs, only update submodules and create symlinks
# --os / -o: specify OS (arch, ubuntu, debian) default: auto-detect
SYNC_ONLY=false
OS=""

for arg in "$@"; do
  case "$arg" in
    --sync|-s) SYNC_ONLY=true ;;
    --os=*) OS="${arg#*=}" ;;
    -o=*) OS="${arg#*=}" ;;
  esac
done

# Auto-detect OS if not specified
if [ -z "$OS" ]; then
  if [ -f /etc/arch-release ]; then
    OS="arch"
  elif [ -f /etc/debian_version ]; then
    OS="ubuntu"
  else
    echo "Error: Could not auto-detect OS. Use --os=arch or --os=ubuntu"
    exit 1
  fi
fi

echo "Detected OS: $OS"

install_dependencies() {
  case "$OS" in
    arch)
      sudo pacman -Syu --noconfirm
      sudo pacman -S --noconfirm git curl zsh tmux neovim eza bat btop zoxide
      yay -S --noconfirm ttf-powerline-fonts || true
      ;;
    ubuntu|debian)
      sudo apt update
      sudo apt install -y git curl zsh cargo tmux neovim fonts-powerline bat btop zoxide
      cargo install eza || true
      # Hack Nerd Font
      mkdir -p ~/.local/share/fonts
      curl -fLo ~/.local/share/fonts/HackNerdFont.ttf \
        https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/HackNerdFontMono-Regular.ttf
      fc-cache -fv
      ;;
    *)
      echo "Error: Unknown OS '$OS'. Use arch, ubuntu or debian"
      exit 1
      ;;
  esac
}

if [ "$SYNC_ONLY" = true ]; then
  [ -d "$HOME/dotfiles" ] || { echo "Error: ~/dotfiles not found. Run full install first."; exit 1; }
  echo "Sync mode: updating submodules and symlinks only."
else
  echo "Installing dependencies..."
  install_dependencies

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
mkdir -p "$HOME/.config/alacritty"
ln -sf "$HOME/dotfiles/.config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"

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
