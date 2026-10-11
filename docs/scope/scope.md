# Scope: dotfiles restructure

Your personal Arch + KDE Plasma setup, rebuilt so every program you configured lives in its own
folder, a new machine can be set up from one install script, and changes flow back with one sync
script. Source: your message on 2026-10-11.

**Build approach:** Tracer Bullet (move one program all the way through the new layout, install and sync first, then repeat for the rest).
**Workflow:** Alpha (after `/develop`, run `/check verify` on the real machine: links resolve, the shell starts, KDE still looks right). `/architect` is the recommended first stop for a feature with a real decision, but skippable when you already know the build. Any feature can carry its own tag to do more or less.

**Decisions already made (your answers, 2026-10-11):**
- Coverage: configs you tuned yourself, plus a package list for every installed program. App state (browsers, chat apps, Spotify) stays out. You get a list of every program left behind so you can pull any of them in.
- Visibility: the repo stays public. Only settings are committed; a deny list strips personal state (recent files, accounts, history, device names) during sync.
- Machines: two profiles. Desktop is Arch + KDE with everything. Server (VPS, VDS, headless boxes) is a lean shell only profile: fast startup, no GUI configs, no fastfetch, no startup tips or shortcut panels, no tmux. The old Ubuntu/WSL code path is dropped; which server distros to support is decided in feature 13.
- Two different lists: the config list (programs with a folder in the repo) and the install list (every program you actually use, configured or not). The install script installs from the install list.
- Prompt: try Starship in place of Powerlevel10k (your call, 2026-10-11).
- System files outside home (`/etc/keyd`, `/etc/default/earlyoom`, pacman hook, K70 HID-BPF fix) are included and installed with sudo, showing the changes first.

_These are recommendations to keep your build orderly, not requirements. Skip anything that does not fit: if you already know how to build a feature, use `/develop` and skip `/architect`. You decide when a feature is `done`._

## At a glance

| # | Feature | Phase | Status |
|---|---------|-------|--------|
| A | Shell config (zsh, p10k) | Existing | existing |
| B | Terminal configs (tmux, ghostty, alacritty) | Existing | existing |
| C | Neovim submodule | Existing | existing |
| D | KDE Mac Dock plasmoid and real-app-icons | Existing | existing |
| E | Old install and sync scripts | Existing | existing |
| 1 | Repo layout and linking method | Foundation | in-progress |
| 2 | Program inventory | Foundation | done |
| 3 | zsh through the new layout | Slice 1 | done |
| 13 | Server profile | Slice 1 | planned |
| 14 | Starship prompt | Slice 1 | done |
| 4 | Terminals and editor | Slice 2 | done |
| 5 | Personal scripts | Slice 3 | done |
| 6 | CLI tool configs | Slice 4 | planned |
| 7 | KDE settings | Slice 5 | planned |
| 8 | KDE extras | Slice 6 | planned |
| 9 | System files | Slice 7 | planned |
| 10 | Package list and bootstrap | Slice 8 | planned |
| 11 | README and architecture docs | Slice 9 | planned |
| 12 | Retire the old scripts | Slice 10 | planned |

## Already in the repo

### A. Shell config (zsh, p10k) (existing)
`.zshrc` and `.p10k.zsh`, symlinked from home. code in `home/zsh/` (moved by feature 3)

### B. Terminal configs (tmux, ghostty, alacritty) (existing)
tmux with `tmux-zen`, Ghostty and Alacritty configs. code in `home/tmux/`, `home/ghostty/`, `home/alacritty/`, `home/bin-desktop/` (moved by feature 4)

### C. Neovim submodule (existing)
Neovim config lives in its own repo (`Gartner24/nvim.lua`), pulled in as a git submodule. code in `home/nvim/.config/nvim` (moved by feature 4)

### D. KDE Mac Dock plasmoid and real-app-icons (existing)
Custom dock widget, icon theme builder and its pacman hook. code in `.local/share/plasma/`, `.local/bin/real-app-icons`, `kde/`

### E. Old install and sync scripts (existing)
`install.sh` and `sync-to-github.sh`. They work badly and get replaced by this plan. code in `install.sh`, `sync-to-github.sh`

## Foundations

### 1. Repo layout and linking method (in-progress)
Decide the folder per program layout, how files get linked or copied into place, and how the sync keeps personal state out of a public repo.
**Done when:** a spec records the layout (one folder per program, scripts folder, system folder, nvim submodule path), how a program is marked desktop only or server too, the link method, how KDE files that KDE rewrites itself are tracked, and the deny list mechanism.
Spec: [0001](../specs/0001-repo-layout-linking/index.md), code in `dot`, `deny.list`, `hooks/`, `profiles/`, `system/`, `kde/`
- [x] Design it (spec): `/architect repo layout and linking method`
- [ ] Build it: `/develop repo layout and linking method`
  - [x] Deny list, commit hook and profile lists (AC-3, AC-9)
  - [x] `dot install` and `dot status` for stow packages (AC-2, AC-4, AC-5, AC-6, AC-14; of AC-13 only the profile submodule init is built, the theme installer call and `--apply-layout` come with feature 8)
  - [x] `dot sync` with scoped staging and submodule guard (AC-10)
  - [x] System and KDE copy paths, one file each (AC-7, AC-8)
  - [x] README and AGENTS.md layout notes, one time history scan (AC-1, AC-15)
  - [ ] claude-config as a submodule, called by dot install and sync (AC-16), after its branch is merged
- [x] Verify it: `/check verify repo layout and linking method`

### 2. Program inventory (done)
Decide which programs get a config folder, which are left behind, and which go on the install list (every program you actually use, a different and longer list than the configured ones).
**Done when:** you have reviewed three lists (configs included with their files, configs left behind, install list of programs you actually use) and each install list entry is marked desktop, server, or both.
Spec: [0002](../specs/0002-program-inventory/index.md)
- [x] Design it (spec): `/architect program inventory`
- [x] Build it: `/develop program inventory`
  - [x] Coverage check and profile cross check (AC-1, AC-3, AC-4, AC-5, AC-6, AC-7)
  - [x] You review the three lists (AC-2, AC-8)
- [ ] Verify it: `/check verify program inventory` (skipped: you reviewed the lists and marked it done, 2026-10-11)

## Slice 1: zsh through the new layout

### 3. zsh through the new layout (done)
Move zsh (`.zshrc`, `.p10k.zsh`, Oh My Zsh plugins) into its own folder and run it through the new install, sync and README, proving the whole path on one program.
**Done when:** a new shell loads from the new location, a dry run install shows the right links, sync picks up an edit, and the README has a zsh section.
Only your own config moves; the Oh My Zsh plugins themselves stay downloaded by `install.sh` until feature 10 (your call, 2026-10-11). Listed in `profiles/server` (both profiles).
Spec: [0001](../specs/0001-repo-layout-linking/index.md), code in `home/zsh/`
- [x] Build it: `/develop zsh through the new layout`
- [x] Verify it: `/check verify zsh through the new layout`

### 13. Server profile (needs a decision)
A lean profile for VPS, VDS and headless servers: a fast zsh with no GUI configs, no fastfetch, no startup tips or shortcut panels, no tmux, and the same scripts installing only server items.
**Done when:** a dry run on a server installs only server items, a new shell there starts noticeably faster than on the desktop (measured with hyperfine), and nothing GUI related is linked.
- [ ] Design it (spec): `/architect server profile`

### 14. Starship prompt · done
Try Starship in place of Powerlevel10k on both profiles, keeping the p10k config around until you decide.
**Done when:** Starship shows what you use from p10k (git, path, errors, timing), shell startup is not slower (measured with hyperfine), and you choose to keep it or go back.
Startup 2026-10-11: 96 ms Starship vs 104 ms p10k (hyperfine, 20 runs, `zsh -i -c exit`). You kept Starship (2026-10-11): `.p10k.zsh`, the p10k fallback in `.zshrc` and the p10k clone in `install.sh` are gone; without starship a shell gets zsh's plain prompt. code in `home/starship/`, `home/zsh/.zshrc`, `profiles/server`
- [x] Build it: `/develop starship prompt`

## Slice 2: Terminals and editor

### 4. Terminals and editor (done)
Move tmux (with `tmux-zen`), Ghostty, Alacritty and the nvim submodule into their folders through the same path.
**Done when:** each program starts with its config from the new location and the nvim submodule still updates from its own repo.
`tmux-zen` went into `home/bin-desktop` (spec 0002); feature 5 adds the other desktop scripts there. The old nvim clone is in `~/.dotfiles-backup/2026-10-11-nvim-clone/` after its work was pushed (your call, 2026-10-11).
Spec: [0001](../specs/0001-repo-layout-linking/index.md) (AC-11, AC-12), code in `home/tmux/`, `home/ghostty/`, `home/alacritty/`, `home/bin-desktop/`, `home/nvim/`
- [x] Build it: `/develop terminals and editor`
- [x] Verify it: `/check verify terminals and editor`

## Slice 3: Personal scripts

### 5. Personal scripts · done
Your own scripts from `~/.local/bin` (not installed tools like uv or yt-dlp) in a scripts folder, linked onto PATH.
**Done when:** every personal script runs from PATH via the repo, and installed tools are untouched.
`xdg-open` is a shim that only wins inside `packettracer-launch` (it puts `~/.local/bin` first); a normal shell still finds `/usr/bin/xdg-open`, as before. `real-app-icons` stays in the old layout until feature 8. No script is server side, so `home/bin/` is not created yet.
Spec: [0002](../specs/0002-program-inventory/index.md) (the `bin-desktop` row), [0001](../specs/0001-repo-layout-linking/index.md) (AC-12), code in `home/bin-desktop/`
- [x] Build it: `/develop personal scripts`
- [x] Verify it: `/check verify personal scripts`

## Slice 4: CLI tool configs

### 6. CLI tool configs
The tuned CLI tools from the inventory (git, mise, tealdeer, yt-dlp, easyeffects presets), each in its own folder, with token files excluded. yazi, btop and mpv have nothing tuned to track.
**Done when:** each tool reads its config from the repo, and no credential file (`.git-credentials`, gh tokens) is tracked.
Spec: [0002](../specs/0002-program-inventory/index.md) (scoped git credential helper, AC-7; drop the `zed` alias from `.zshrc`)
- [ ] Build it: `/develop CLI tool configs`

## Slice 5: KDE settings

### 7. KDE settings (needs a decision)
Your full KDE setup: look and feel, themes, color schemes, window rules, shortcuts, panels, input, power, Kvantum, panel colorizer, with personal state stripped.
**Done when:** a fresh KDE session restored from the repo matches your current desktop, and the committed files contain no recent files, accounts or device names.
- [ ] Design it (spec): `/architect KDE settings`

## Slice 6: KDE extras

### 8. KDE extras
Mac Dock plasmoid, real-app-icons and its pacman hook, wallpapers, aurorae and color scheme files, in the KDE folder.
**Done when:** the dock and icon theme install from the repo and the pacman hook rebuilds icons after an update.
- [ ] Build it: `/develop KDE extras`

## Slice 7: System files

### 9. System files
`/etc/keyd` (arrow key fix), `/etc/default/earlyoom`, the pacman hook, the K70 HID-BPF fix and your user systemd units, installed with sudo after showing what changes.
**Done when:** install shows a diff for each system file before writing it, and after install the arrow key fix, earlyoom and the K70 keyboard work.
- [ ] Build it: `/develop system files`

## Slice 8: Package list and bootstrap

### 10. Package list and bootstrap
Turn the install list from the inventory (programs you actually use, not just the configured ones) into files the install script reads, split into desktop and server, and into pacman, AUR and flatpak.
**Done when:** install on a new desktop offers every program on the install list, install on a server offers only server items, and sync flags programs installed since the list was last reviewed.
Spec: [0002](../specs/0002-program-inventory/index.md) (the install list and its Follow-up: yay first, Plasma without `discover`)
- [ ] Build it: `/develop package list and bootstrap`

## Slice 9: README and architecture docs

### 11. README and architecture docs
A README that matches the new layout: what is included, how to install, how to sync, how to add a program.
**Done when:** every folder in the repo is described and the install and sync steps in the README work as written.
- [ ] Build it: `/develop README and architecture docs`

## Slice 10: Retire the old scripts

### 12. Retire the old scripts
Remove the old `install.sh` and `sync-to-github.sh`, the Ubuntu path and NVM install, once the new scripts cover everything.
**Done when:** the old scripts are gone and nothing in the repo or README points to them.
- [ ] Build it: `/develop retire the old scripts`

## Deferred
Out of scope for the current build pass, kept so the plan stays honest.
- **claude-config reorganization**: same treatment for the `~/claude-config` repo, after dotfiles is done (needs a decision). Where it sits in dotfiles (submodule at `claude-config/`, both profiles) is already decided in spec 0001, AC-16.

## Legend

**The decision box.** Every feature carries exactly one, the sub-task whose label ends with `(spec)`. Skills locate it by that `(spec)` suffix, never by an exact label. Every other box is an execution box.

- **Next step** = the first unticked box.
- **needs a decision** = run `/architect` first; otherwise straight to `/develop`.
- **Status** `planned` to `in-progress` to `done`, plus `existing` (before this workflow) and `dropped` (kept for history).
- **Workflow** Alpha: after `/develop`, run `/check verify`. That is the suggested point to call a feature done.
- **Atomic build tasks live in the spec's `## Build plan`, not here.**
