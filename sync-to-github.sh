#!/usr/bin/env bash
# Sync configs from $HOME into dotfiles repo and push to GitHub.
# Neovim is managed separately via its own repo.
set -e

DOTFILES="$HOME/dotfiles"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

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
echo -e "║       Dotfiles Sync to GitHub        ║"
echo -e "╚══════════════════════════════════════╝${RESET}\n"

[ -d "$DOTFILES" ] || error "Dotfiles directory not found at $DOTFILES"

# ── Copy real configs from $HOME into repo ────────────────────────────────────
copy_config() {
  local src="$1"
  local dest="$2"
  local real_src
  real_src=$(realpath "$src" 2>/dev/null) || { warn "Source not found: $src — skipping."; return; }
  local real_dest
  real_dest=$(realpath "$DOTFILES/$dest" 2>/dev/null || echo "$DOTFILES/$dest")

  if [ "$real_src" = "$real_dest" ]; then
    info "Skipping $dest (symlink points to repo — already in sync)"
    return
  fi

  mkdir -p "$(dirname "$DOTFILES/$dest")"
  cp "$real_src" "$DOTFILES/$dest"
  success "Copied $dest"
}

cd "$DOTFILES"

copy_config "$HOME/.zshrc"                          ".zshrc"
copy_config "$HOME/.tmux.conf"                      ".tmux.conf"
copy_config "$HOME/.config/alacritty/alacritty.toml" ".config/alacritty/alacritty.toml"

# ── Commit & push ─────────────────────────────────────────────────────────────
git add .

if git diff --cached --quiet; then
  warn "Nothing changed — nothing to commit."
  echo ""
  exit 0
fi

CHANGED=$(git diff --cached --name-only | tr '\n' ' ')
info "Staged: $CHANGED"

COMMIT_MSG="sync: ${CHANGED% } — $TIMESTAMP"
git commit -m "$COMMIT_MSG"

info "Pushing to GitHub..."
git push

echo ""
success "Done! Pushed: $CHANGED"
echo ""
