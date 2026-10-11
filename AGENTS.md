# dotfiles

Personal Linux config with two profiles: desktop (Arch, KDE Plasma 6 on Wayland) and a lean
headless server profile (planned, see `docs/scope/scope.md`). `install.sh` still has an old Ubuntu/WSL path. Public repo: `github.com/Gartner24/dotfiles`.

## Stack

- **Language / Runtime**: zsh (Oh My Zsh + Powerlevel10k), bash for scripts, QML for the KDE plasmoid
- **Framework**: none; plain files symlinked into `$HOME`
- **Key dependencies**: Oh My Zsh, tmux, Ghostty, Alacritty, Neovim, mise, zoxide, fzf, fd, eza, bat, yazi
- **Package manager**: pacman + yay (Arch), apt (Ubuntu); no project manifest

## Build approach

Tracer Bullet (move one program all the way through the new layout, install and sync first, then repeat for the rest).

## Commands

```bash
# Install on a new machine (deps, Oh My Zsh, symlinks, nvim clone)
./install.sh            # --os=arch|ubuntu, --gui, --sync (submodules + symlinks only)

# Copy changed configs from $HOME into the repo, commit and push
./sync-to-github.sh

# New layout: link, report, sync (see README "Layout")
./dot install desktop -n   # dry run; then without -n
./dot status
./dot sync                 # scoped staging, asks before new files and before push

# Check shell config after editing
zsh -n home/zsh/.zshrc
```

No tests or CI.

## Rules

- New layout (spec 0001): each program is a stow package under `home/<pkg>/`, mirroring its path
  under `~` (`home/zsh/.zshrc`), listed by name in `profiles/server` or `profiles/desktop`, and
  linked by `./dot install`. System files go under `system/<name>/` (absolute paths), KDE keys in
  `kde/allow.list`. No new program config goes at the repo root.
- Old layout, until each program's slice moves it: files at the root mirror their `$HOME` path and
  are symlinked by `install.sh`. A program is in the old layout or the new one, never both.
- `deny.list` plus `hooks/pre-commit` (enabled by `dot install`) refuse commits adding personal
  state. Do not bypass with `--no-verify`.
- `.config/nvim` is a git submodule (`github.com/Gartner24/nvim.lua`). Commit nvim changes in that
  repo first, then commit the updated submodule pointer here.
- The repo is public: never commit keys, tokens, `~/.config/claude-fb/keys.env`, history files,
  or machine state (caches, window positions, recent files).
- Comments in `home/zsh/.zshrc` explain why a setting exists (often a past failure); keep that style.
- Shell functions that touch the system ask before destructive steps (`read -q`), see `wtclean`, `freeram`.
- `kde/real-app-icons.hook` installs to `/etc/pacman.d/hooks/` with sudo (Arch only).

## Gotchas

- `~/.zshrc` and `~/.p10k.zsh` link to `home/zsh/`; editing either edits the repo. Oh My Zsh and its plugins are not in the repo (`install.sh` clones them).
- `sync-to-github.sh` runs `git add .` and pushes: anything untracked in the repo gets published.
- `install.sh` still installs NVM, but `.zshrc` moved to mise; README only lists nvim, zsh and tmux.

## Agent skills

Declined: registry Agent Skills and MCP servers (Claude setup lives in the separate `~/claude-config` repo)

## Context files

<!-- Nested AGENTS.md files are listed here as they are created -->

_Drafted by /audit from the repo, worth a quick human pass. Edit freely: once a line stops matching this draft, later runs treat it as curated and will flag rather than overwrite it._
