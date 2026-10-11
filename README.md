# Dotfiles

This repo contains my development environment configuration:
- Neovim (as a git submodule: [nvim.lua](https://github.com/Gartner24/nvim.lua))
- Zsh + Oh My Zsh + plugins
- Tmux

Everything is portable across Linux systems (including WSL).

---

## Layout (moving in, program by program)

The repo is moving to one folder per program, managed by `./dot`. Programs not moved yet
still live at the root and are handled by `install.sh` and `sync-to-github.sh` below.

```
dot                 install | sync | status
deny.list           regex per line; anything matching is never committed
profiles/server     packages for every machine
profiles/desktop    desktop extras (server is always included)
home/<pkg>/...      a program's files, paths relative to ~, linked with GNU Stow
system/<name>/...   files outside home (system/keyd/etc/keyd/default.conf), copied with sudo
kde/allow.list      KDE keys to keep: <rcfile> <Group> <Key>
kde/<rcfile>        only those keys, read from and written back to the live file
hooks/pre-commit    refuses a commit that adds a deny.list match
docs/               scope and specs, never linked
```

```bash
./dot install desktop -n   # dry run: every link, backup and system diff, changes nothing
./dot install desktop      # or server; the profile is saved for later runs
./dot status               # link state and drift, exits 1 on a problem
./dot sync                 # pull KDE keys and system drift in, commit, ask before push
```

- Files are linked one by one (`stow --no-folding`), never whole folders.
- A real file in the way is moved to `~/.dotfiles-backup/<timestamp>/` first.
- System files show a diff and ask before each `sudo install`; KDE changes need a log out.
- `dot sync` only stages `home`, `system`, `kde` and `profiles`, and asks before adding new files.
- To add a program: put its files under `home/<pkg>/` as they sit under `~`, add `<pkg>` to a profile, run `./dot install`.

### zsh (`home/zsh`, both profiles)

```
home/zsh/.zshrc      shell config: history, Oh My Zsh plugin list, aliases, functions (fixall, up, nosleep...)
home/zsh/.p10k.zsh   Powerlevel10k prompt config
```

- Listed in `profiles/server`, so every machine gets it. `~/.zshrc` and `~/.p10k.zsh` link here: edit either one and the repo changes.
- Only your own config lives here. Oh My Zsh, Powerlevel10k and the plugins (autosuggestions, syntax highlighting, completions) are downloaded by `install.sh`; which plugins load is set by `plugins=(...)` in `.zshrc`.
- On a new machine: `./install.sh` (Oh My Zsh may write its own `~/.zshrc`), then `./dot install desktop`, which moves that file to `~/.dotfiles-backup/` and links the repo one. Then `exec zsh`.
- After editing: `zsh -n home/zsh/.zshrc` to check syntax, `./dot sync` to commit.

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

