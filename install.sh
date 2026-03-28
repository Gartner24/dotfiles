#!/usr/bin/env bash
set -e

# ── Args ──────────────────────────────────────────────────────────────────────
SYNC_ONLY=false
OS=""
HAS_GUI=false

for arg in "$@"; do
  case "$arg" in
    --sync|-s) SYNC_ONLY=true ;;
    --os=*) OS="${arg#*=}" ;;
    -o=*) OS="${arg#*=}" ;;
    --gui) HAS_GUI=true ;;
  esac
done

# ── Auto-detect OS ────────────────────────────────────────────────────────────
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

# ── Auto-detect GUI ───────────────────────────────────────────────────────────
if [ "$HAS_GUI" = false ]; then
  if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ] || [ "$XDG_SESSION_TYPE" = "x11" ] || [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    HAS_GUI=true
  fi
fi

echo "OS: $OS | GUI: $HAS_GUI"

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()    { echo -e "${CYAN}  →${RESET} $1"; }
success() { echo -e "${GREEN}  ✔${RESET} $1"; }
warn()    { echo -e "${YELLOW}  ⚠${RESET} $1"; }
error()   { echo -e "${RED}  ✘${RESET} $1"; exit 1; }

echo -e "\n${YELLOW}╔══════════════════════════════════════╗"
echo -e "║        Dotfiles Installer            ║"
echo -e "╚══════════════════════════════════════╝${RESET}\n"

# ── Dependencies ──────────────────────────────────────────────────────────────
install_dependencies() {
  case "$OS" in
    arch)
      info "Installing Arch packages..."
      sudo pacman -Syu --noconfirm
      sudo pacman -S --noconfirm git curl zsh tmux neovim eza bat btop zoxide fzf docker docker-compose openssh

      # GUI-only packages
      if [ "$HAS_GUI" = true ]; then
        info "Installing GUI packages..."
        yay -S --noconfirm ttf-hack-nerd alacritty
      fi
      ;;

    ubuntu|debian)
      info "Installing Ubuntu packages..."
      sudo apt update
      sudo apt install -y git curl zsh tmux neovim bat btop zoxide fzf docker.io docker-compose openssh-server unzip

      # eza (not in apt)
      if ! command -v eza &>/dev/null; then
        info "Installing eza..."
        curl -Lo /tmp/eza.tar.gz https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz
        tar -xzf /tmp/eza.tar.gz -C /tmp
        sudo mv /tmp/eza /usr/local/bin/eza
      fi

      # GUI-only packages
      if [ "$HAS_GUI" = true ]; then
        info "Installing GUI packages..."
        sudo apt install -y fonts-hack

        # Alacritty
        if ! command -v alacritty &>/dev/null; then
          sudo apt install -y alacritty || warn "Alacritty not available in apt, install manually."
        fi
      fi

      # Hack Nerd Font (GUI only)
      if [ "$HAS_GUI" = true ]; then
        info "Installing Hack Nerd Font..."
        mkdir -p ~/.local/share/fonts
        curl -fLo ~/.local/share/fonts/HackNerdFontMono-Regular.ttf \
          https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/HackNerdFontMono-Regular.ttf
        fc-cache -fv
      fi
      ;;

    *)
      error "Unknown OS '$OS'. Use arch, ubuntu or debian"
      ;;
  esac

  # ── Docker group ────────────────────────────────────────────────────────────
  if groups "$USER" | grep -qv docker; then
    sudo usermod -aG docker "$USER"
    warn "Added $USER to docker group — re-login required for effect"
  fi

  # ── NVM ─────────────────────────────────────────────────────────────────────
  if [ ! -d "$HOME/.nvm" ]; then
    info "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
  else
    info "NVM already installed."
  fi

  # ── mise ────────────────────────────────────────────────────────────────────
  if ! command -v mise &>/dev/null; then
    info "Installing mise..."
    curl https://mise.run | sh
  else
    info "mise already installed."
  fi
}

# ── Clone dotfiles ─────────────────────────────────────────────────────────────
if [ "$SYNC_ONLY" = true ]; then
  [ -d "$HOME/dotfiles" ] || error "~/dotfiles not found. Run full install first."
  info "Sync mode: updating submodules and symlinks only."
else
  info "Installing dependencies..."
  install_dependencies

  info "Cloning dotfiles repo..."
  if [ ! -d "$HOME/dotfiles" ]; then
    git clone --recurse-submodules https://github.com/Gartner24/dotfiles.git "$HOME/dotfiles"
  else
    warn "Dotfiles repo already exists at ~/dotfiles"
  fi
fi

cd "$HOME/dotfiles"
[ "$SYNC_ONLY" = true ] && git pull
git submodule update --init --recursive

# ── Oh My Zsh + plugins ───────────────────────────────────────────────────────
if [ "$SYNC_ONLY" = false ]; then
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    info "Oh My Zsh already installed."
  fi

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  info "Installing Zsh plugins and theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git     "$ZSH_CUSTOM/themes/powerlevel10k"              2>/dev/null || true
  git clone https://github.com/zsh-users/zsh-autosuggestions            "$ZSH_CUSTOM/plugins/zsh-autosuggestions"       2>/dev/null || true
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"   2>/dev/null || true
  git clone https://github.com/zsh-users/zsh-completions                "$ZSH_CUSTOM/plugins/zsh-completions"           2>/dev/null || true
fi

# ── Symlinks ──────────────────────────────────────────────────────────────────
info "Creating symlinks..."

ln -sf "$HOME/dotfiles/.zshrc"   "$HOME/.zshrc"
ln -sf "$HOME/dotfiles/.tmux.conf" "$HOME/.tmux.conf"

# Alacritty only on GUI
if [ "$HAS_GUI" = true ]; then
  mkdir -p "$HOME/.config/alacritty"
  ln -sf "$HOME/dotfiles/.config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
fi

# ── Neovim ────────────────────────────────────────────────────────────────────
if [ ! -d "$HOME/.config/nvim/.git" ]; then
  if [ -d "$HOME/.config/nvim" ]; then
    error "~/.config/nvim exists but is not a git repo. Refusing to overwrite."
  fi
  info "Cloning nvim config..."
  git clone https://github.com/Gartner24/nvim.lua.git "$HOME/.config/nvim"
else
  info "Updating nvim config..."
  (cd "$HOME/.config/nvim" && git fetch && git pull)
fi

# ── Default shell ─────────────────────────────────────────────────────────────
if [ "$SHELL" != "$(which zsh)" ]; then
  info "Setting zsh as default shell..."
  chsh -s "$(which zsh)"
fi

echo ""
success "Installation complete!"
info "Restart your shell or run: exec zsh"
echo ""
