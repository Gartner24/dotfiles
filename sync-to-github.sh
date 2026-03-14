#!/usr/bin/env bash
# Sync configs from $HOME into dotfiles repo and push to GitHub.
# Neovim is managed separately via its own repo.
set -e

DOTFILES="$HOME/dotfiles"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
CHANGED=()

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

# ── Copy real configs from $HOME into repo ─────────────────────────────────
cd "$DOTFILES"

# Use cat to avoid "same file" when $HOME configs are symlinks into this repo
cat "$HOME/.zshrc" > .zshrc
cat "$HOME/.tmux.conf" > .tmux.conf
mkdir -p .config/alacritty
cat "$HOME/.config/alacritty/alacritty.toml" > .config/alacritty/alacritty.toml

# ── Commit & push ─────────────────────────────────────────────────────────
git add .

# Check if there's anything staged
if git diff --cached --quiet; then
  warn "Nothing changed — nothing to commit."
  echo ""
  exit 0
fi

# Get list of changed files for commit message
CHANGED=$(git diff --cached --name-only | tr '\n' ' ')

info "Staged: $CHANGED"

COMMIT_MSG="sync: ${CHANGED% } — $TIMESTAMP"
git commit -m "$COMMIT_MSG"

info "Pushing to GitHub..."
git push

echo ""
success "Done! Pushed: $CHANGED"
echo ""
