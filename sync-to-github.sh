#!/usr/bin/env bash
# Sync zsh/tmux configs from $HOME into dotfiles and push to GitHub.
# Neovim is managed separately: push from ~/.config/nvim to its own repo.
set -e

DOTFILES="$HOME/dotfiles"

echo "Syncing configs into dotfiles..."
cp "$HOME/.zshrc" "$DOTFILES/.zshrc"
cp "$HOME/.tmux.conf" "$DOTFILES/.tmux.conf"

cd "$DOTFILES"

if git diff --quiet .zshrc .tmux.conf 2>/dev/null; then
  echo "No changes to commit."
  exit 0
fi

git add .zshrc .tmux.conf
git commit -m "Sync zsh and tmux configs"
git push

echo "Done. Pushed to GitHub."
