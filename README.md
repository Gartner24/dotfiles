# Dotfiles

This repo contains my development environment configuration:
- Neovim (as a git submodule: [nvim.lua](https://github.com/Gartner24/nvim.lua))
- Zsh + Oh My Zsh + plugins
- Tmux

Everything is portable across Linux systems (including WSL).

---

## Installation

### 1. Clone with submodules
```bash
git clone --recurse-submodules https://github.com/Gartner24/dotfiles.git ~/dotfiles
cd ~/dotfiles
```


If you already cloned without `--recurse-submodules`:
```bash
git submodule update --init --recursive
```

### 2. Run the install script
This will install dependencies, configure Oh My Zsh, pull plugins, and symlink all configs.


```bash
cd ~/dotfiles
./install.sh
```


If the script is not executable, run:
```bash
chmod +x install.sh
./install.sh
```

### 3. Restart shell
```bash
exec zsh
```

---


## Updating submodules

When `nvim.lua` is updated:
```bash
cd ~/dotfiles/.config/nvim
git pull origin main
cd ~/dotfiles
git add .config/nvim
git commit -m "Update nvim submodule"
git push
```

---

## Notes
- Keep `$HOME/.local/bin` in your PATH for Python/pipx tools.
- On WSL, clipboard behavior differs (uses `clip.exe` instead of `xclip`).
- Oh My Zsh itself is not committed; the install script downloads it.

