# 0002. Program inventory: rationale

## Context

The scope keeps two lists apart: configs the repo tracks (a folder per program) and programs a new machine installs (every program you use, configured or not). Features 4 to 10 each move or install part of them, so without one agreed inventory each feature would decide membership again, and the install script would copy whatever happens to be installed today.

"Installed today" is a poor proxy. On 2026-10-11 this machine had 300 explicit pacman packages (12 from the AUR), 1 flatpak, 11 pipx tools, 2 uv tools, node through mise, one npm global and a few hand downloaded binaries. Both the `plasma` and the `kde-applications` groups are installed whole, so many KDE apps were never chosen one by one.

The repo is public. Some configs next to the tuned ones hold tokens (`gh/hosts.yml`, the spotdl config, `.git-credentials`), and `.gitconfig` points git at a plaintext credential store.

## Options considered

### Option 1: Evidence, then prune (chosen)

Keep a program when it has proof of use (KDE launch history, zsh history), a tuned config, or a system role; offer the rest as drop groups.

- Pro: the list reflects use, and pruning is a few group decisions instead of 300.
- Con: the evidence misses programs started by other programs or outside the menu; a wrong drop is fixed by hand.

### Option 2: Mirror everything installed

Install list equals `pacman -Qqe` plus the other sources.

- Pro: nothing you use can be missed; no judgment needed.
- Con: carries the never launched KDE suite and leftovers (two `yt-dlp` copies, X11 bits) to every machine, forever.

### Option 3: Start empty, add each by hand

- Pro: every entry is a conscious choice.
- Con: about 330 decisions; the slowest path, and easy to forget a library a program needs.

For KDE: `plasma-meta` plus named apps was chosen over naming every package (long, drifts as KDE renames) and over `kde-applications-meta` (installs the whole suite you mostly do not use).

## Rationale

The scope asked for programs you *actually use*, which rules out Option 2, and Option 3 costs far more than the problem warrants. Evidence first keeps the work to a handful of group decisions while every package still lands somewhere visible (the coverage check proves it), so a mistake costs one line moved, not a missing program you never notice.

`plasma-meta` tracks what Arch considers a complete Plasma, so a KDE rename or split does not break the list; the price is two packages this machine lacks (`discover`, `plasma-systemmonitor`).

Recommended without asking (your call to reverse):
- `kwin-x11`, `kgamma`, `oxygen-cursors` dropped: the session is Wayland and nothing launched them. Runner up: keep `kwin-x11` as an X11 fallback session.
- `fastfetch` on desktop only: the scope keeps it off servers.
- Mise config on the server profile: you put `mise` on servers, and without its config it installs no runtime.
- `cloudflared`, `uv`, `git-filter-repo` on desktop: the server set you chose does not include them.
- `easyeffectsrc` excluded from the easyeffects package: window and last used state, not presets.
- Steam's and QEMU's libraries (`lib32-*`, `libxcrypt-compat`, `edk2-ovmf`) and three Plasma libraries treated as dependencies, since a listed package requires each (`pacman -Qi`, Required By).
- `fuse2`, `libappindicator`, `dnsmasq` kept explicit: nothing requires them, they are optional features (AppImages, tray icons, libvirt networking).

## Evidence (2026-10-11)

**Method.** File access times were tried first and discarded: nearly every binary showed an access on 2026-10-11, so `relatime` gave no signal. Used instead:
- KDE activity database (`~/.local/share/kactivitymanagerd/resources/database`, table `ResourceScoreCache`, `applications:` entries): launches from the menu, KRunner and the task manager, with last launch date.
- zsh history: command name frequency (counted locally, nothing copied).
- Config folders in `~/.config` and dotfiles in `~`: size, date, and whether the content differs from defaults.
- `pacman -Qqe`, `pacman -Qqem`, `flatpak list`, `pipx list`, `uv tool list`, `mise ls`, `npm ls -g`, `pacman -Qqg plasma kde-applications`, `pacman -Si`, `yay -Si`, `/var/log/pacman.log`.

**GUI launches with evidence** (last launch): Brave and its web apps (2026-10-11), Spotify (10-11), Sober (10-11), KRecorder (10-09), Kalk (10-08), Discord (10-08), Mendeley (10-06), Firefox (10-05), KolourPaint (10-03), VS Code (10-01), Ghostty (10-01), Alacritty (09-30), Figma (09-30), KDiskFree (09-24), LibreOffice Calc (09-10), Kamoso (09-08), OpenRGB (09-08), System Settings (09-07), Packet Tracer (09-05), Karbon (09-05), Proton VPN (08-09), Yazi (08-07), btop (08-07), Obsidian (08-06), KTimer (08-02), Picard (07-30), GIMP (07-29), ROG Control Center (07-27), BleachBit (07-27), virt-manager (07-23), EasyEffects (07-23), Gwenview (07-23), Steam (06-25), Telegram (06-24). Documents opened through Dolphin, Okular, Gwenview, Calligra, Ark and Spectacle add to those.

**CLI use from zsh history** (top): git, sudo, nvim, yay, pnpm, claude, curl, npm, go, tmux, yarn, unzip, pacman, node, ssh, python3, asusctl, pipx, ping, aws, arduino-cli, iw, tldr, nmap, ethtool, docker, uvicorn, spotdl, ffuf, gh, rsync, marimo, jupyter, aircrack-ng.

**Zed.** `/var/log/pacman.log`: installed 2026-03-14, last upgraded to 1.11.3, removed 2026-07-22. `~/.local/share/zed` (data from March) and the `zed='zeditor'` alias in `.zshrc` remain. The removal was on purpose: Zed stays off the install list, its config is left behind, and the alias goes (feature 6).

**Tuned configs found**: `.gitconfig` (delta pager, zdiff3, ssh rewrite, gh credential helper plus a plaintext store), `.config/git/ignore` (agent tool folders), `mise/config.toml` (node 24), `tealdeer/config.toml` (colors, no auto update), `yt-dlp/config` (`--js-runtimes node`), `zed/settings.json` (vim mode, Cursor keymap, telemetry off), EasyEffects presets, OpenRGB profiles (`green.orp`, `white.orp`), `btop.conf` (full dump, not picked). Empty folders: `mpv`, `fontconfig`, `autostart`, `htop`, btop and zed `themes`.

**Hand installed binaries and their packages**: `cloudflared` -> extra `cloudflared`; `uv`, `uvx` -> extra `uv`; `git-filter-repo` -> extra `git-filter-repo`; `stripe` -> AUR `stripe-cli-bin` (maintained, current; `stripe-cli` is flagged out of date).

**Not installed today but present as config**: konsole, kate, yakuake (rc files only).
