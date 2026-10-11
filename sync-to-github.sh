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

cd "$DOTFILES"

# tmux, alacritty and ghostty moved to home/, synced by ./dot sync

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
