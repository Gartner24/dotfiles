# dotfiles

Personal Linux config with two profiles: desktop (Arch, KDE Plasma 6 on Wayland) and a lean
headless server profile for Arch, Debian 12+ and Ubuntu 22.04+ (spec 0003; its package install comes with feature 10, see `docs/scope/scope.md`). `install.sh` still has an old Ubuntu/WSL path. Public repo: `github.com/Gartner24/dotfiles`.

## Stack

- **Language / Runtime**: zsh (Oh My Zsh + Starship prompt), bash for scripts, QML for the KDE plasmoid
- **Framework**: none; plain files symlinked into `$HOME`
- **Key dependencies**: Oh My Zsh, tmux, Ghostty, Alacritty, Neovim, mise, zoxide, fzf, fd, eza, bat, yazi
- **Package manager**: pacman + yay (Arch), apt (Ubuntu); no project manifest

## Build approach

Tracer Bullet (move one program all the way through the new layout, install and sync first, then repeat for the rest).

## Commands

```bash
./install.sh                # new machine; --os=arch|ubuntu, --gui, --sync (submodules + symlinks only)
./sync-to-github.sh         # copy changed configs from $HOME into the repo, commit, push
./dot install desktop -n    # dry run; then without -n. Also ./dot status, ./dot sync (asks before new files and push)
zsh -n home/zsh/.zshrc      # check shell config after editing
tests/dot-status.sh         # throwaway repo and HOME
tests/global-hooks.sh       # throwaway repos
tests/server-profile.sh [image]   # docker containers; exits 2 without docker
```

No CI.

## Rules

- New layout (spec 0001): each program is a stow package under `home/<pkg>/`, mirroring its path
  under `~` (`home/zsh/.zshrc`), listed by name in `profiles/server` or `profiles/desktop`, and
  linked by `./dot install`. System files go under `system/<name>/` (absolute paths), KDE keys in
  `kde/allow.list`. No new program config goes at the repo root.
- Old layout, until each program's slice moves it: files at the root mirror their `$HOME` path and
  are symlinked by `install.sh`. A program is in the old layout or the new one, never both.
- `deny.list` plus `hooks/pre-commit` (enabled by `dot install`) refuse commits adding personal
  state. Do not bypass with `--no-verify`.
- `home/nvim/.config/nvim` is a git submodule (`github.com/Gartner24/nvim.lua`). Commit nvim changes in that
  repo first, then commit the updated submodule pointer here.
- The repo is public: never commit keys, tokens, `~/.config/claude-fb/keys.env`, history files,
  or machine state (caches, window positions, recent files).
- Comments in `home/zsh/.zshrc` explain why a setting exists (often a past failure); keep that style.
- `home/zsh/.zshrc` is shared with servers (spec 0003): no desktop programs, GUI variables or
  `/home/santiago` paths in it. Desktop shell config goes in `home/zsh-desktop/.config/zsh/conf.d/desktop.zsh`
  (Oh My Zsh only in `conf.d/early/omz.zsh`), and an alias is set only when its tool is on PATH.
  After moving shell config, compare the full `alias`, `functions` and `print -l $path` output before and after.
- Shell functions that touch the system ask before destructive steps (`read -q`), see `wtclean`, `freeram`.
- `kde/real-app-icons.hook` installs to `/etc/pacman.d/hooks/` with sudo (Arch only).

## Gotchas

- `~/.zshrc` and `~/.config/starship.toml` link into `home/`; editing either edits the repo. Oh My Zsh and its plugins are not in the repo.
- `sync-to-github.sh` runs `git add .` and pushes: anything untracked gets published.

## Agent skills

Declined: registry Agent Skills and MCP servers (Claude setup lives in the separate `~/claude-config` repo)

## Context files

<!-- Nested AGENTS.md files are listed here as they are created -->

_Drafted by /audit from the repo, worth a quick human pass. Edit freely: once a line stops matching this draft, later runs treat it as curated and will flag rather than overwrite it._
