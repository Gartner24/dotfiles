# 0002. Program inventory: config list, left behind list, install list

**Date**: 2026-10-11
**Status**: Proposed

## Summary

This spec decides which programs get a config folder in the repo, which configs stay behind, and which programs a new machine installs. The install list keeps a program only when there is proof you use it (KDE launch history, zsh history, a config you tuned, or a system role), and you pruned the rest. KDE comes in as one meta package (a package that only pulls in others) plus the apps you actually use. Each install entry is marked server or desktop (desktop also gets everything server gets), and later features build from these lists instead of guessing.

## Requirements

**User stories**:
- As the owner, I want one reviewed list of the configs the repo tracks, so features 4 to 9 move exactly those and nothing else.
- As the owner, I want to see every config left behind and why, so I can pull one in later on purpose.
- As the owner, I want an install list of programs I actually use, each marked server or desktop, so feature 10 can turn it into package files without asking again.

**Acceptance criteria**:
- **AC-1**: The config list names, per package, its folder under `home/` (or `system/`, `kde/`, a submodule), the exact files it tracks, its profile, and the feature that moves it.
- **AC-2**: The left behind list groups every config not tracked, with a reason per group. Credential files are in their own group and are never tracked by any package.
- **AC-3**: Every install list entry has a name, a source (`pacman`, `aur`, `flatpak`, `pipx`, `mise`) and a profile (`server` or `desktop`). Entries tied to specific hardware carry an `hw:` tag naming it.
- **AC-4**: Every package from `pacman -Qqe` on this machine (300 on 2026-10-11, AUR included) appears exactly once across these lists: install list, comes as a dependency, base reference, or dropped. The coverage check in *Build plan* prints the count of missing or duplicated names, and it is 0.
- **AC-5**: Every config package's program is on the install list with the same profile or wider (a server package never configures a desktop only program).
- **AC-6**: Programs installed by something other than `dot` are listed with their owner (claude-config, the work setup, feature 7), and are not on the install list.
- **AC-7**: The repo copy of `~/.gitconfig` drops the global `credential.helper = store` and keeps `store` only under `[credential "https://gitlab.freedesktop.org"]`. `~/.git-credentials` stays untracked (already in `deny.list`).
- **AC-8**: You have reviewed the three lists and marked the scope feature done (the scope's *Done when*).

## Decision

**Chosen option**: Option 1: Evidence, then prune.

A program stays on the install list when it has proof of use, a tuned config, or a system role, minus the groups you dropped; KDE is `plasma-meta` plus named apps; pipx, mise and flatpak entries sit beside pacman and AUR; hand downloaded binaries map to packages.

## Rationale

Reasoning, options and the usage evidence: see [rationale.md](rationale.md).

## Feature design

**Data model sketch**: two record shapes, no storage beyond this file. A config entry is package (required), files (required), profile (`server` | `desktop`), moving feature. An install entry is name (required), source (`pacman` | `aur` | `flatpak` | `pipx` | `mise`), profile, `hw:` tag (optional). Feature 10 picks the file format the installer reads.

### Config list (tracked)

| Package | Files (relative to `~` unless absolute) | Profile | Moved by |
|---|---|---|---|
| zsh | `.zshrc`, `.p10k.zsh` | server | feature 3 (done) |
| git | `.gitconfig` (store helper scoped, AC-7), `.config/git/ignore` | server | feature 6 |
| mise | `.config/mise/config.toml` (node 24) | server | feature 6 |
| nvim | `.config/nvim` (submodule) | server | feature 4 |
| starship | `.config/starship.toml` | server | feature 14 |
| tmux | `.tmux.conf` | desktop | feature 4 |
| ghostty | `.config/ghostty/` | desktop | feature 4 |
| alacritty | `.config/alacritty/` | desktop | feature 4 |
| tealdeer | `.config/tealdeer/config.toml` | desktop | feature 6 |
| yt-dlp | `.config/yt-dlp/config` | desktop | feature 6 |
| easyeffects | `.config/easyeffects/db/{equalizer,compressor,multibandcompressor,gate,limiter}rc` | desktop | feature 6 |
| bin-desktop | `.local/bin/{tmux-zen,xdg-open,packettracer-launch,innioasis-updater,vba_extract.py,searxng-mcp}` | desktop | feature 5 |
| keyd | `system/keyd` -> `/etc/keyd/default.conf` | desktop | spec 0001 (done) |
| earlyoom, pacman hook, K70 HID-BPF fix | `system/<name>/...` | desktop | feature 9 |
| KDE keys | `kde/allow.list` and the files it names | desktop | feature 7 decides the keys |
| kde-theme | submodule: Global Theme, Mac Dock, real-app-icons, Kvantum MacTahoe, panel colorizer | desktop | feature 8 |
| claude-config | submodule | server | spec 0001 AC-16 |

`easyeffectsrc` stays out of the easyeffects package: it holds window and last used state, not the presets.

### Left behind (not tracked)

| Group | Items | Why |
|---|---|---|
| Credentials | `~/.git-credentials`, `.config/gh/hosts.yml`, `.config/watch/.env`, `.config/claude-fb/`, `~/.aws`, `~/.ssh`, `~/.gnupg`, `~/.wakatime.cfg`, `.config/spotdl/config.json` (holds a Genius token and client secret) | Secrets; public repo. Never tracked. |
| App state | browsers (`BraveSoftware`, `chromium`, `google-chrome*`, `microsoft-edge`, `mozilla`, `opera`, `vivaldi`, `falkon`), chat (`discord`, `Signal`, `zoom*`, `wasistlos`), `spotify`, `Claude`, `Cursor`, `cursor`, `obsidian`, `libreoffice`, `GIMP`, `inkscape`, `obs-studio`, `kdenliverc`, `Mendeley Reference Manager`, `figma-linux`, `MusicBrainz`, `OpenRGB`, `vlc`, `wireshark`, `libvirt`, `Proton` | Scope decision 2026-10-11: app state stays out. Any one can be pulled in later. |
| Synced elsewhere | `.config/Code/User/` (VS Code) | VS Code Settings Sync through GitHub. |
| Defaults or empty | `gh/config.yml` (defaults), `btop`, `htop`, `mpv`, `fontconfig`, `autostart`, `kate` external tools (KDE defaults), `uv/uv-receipt.json` | Nothing tuned to keep. |
| Apps no longer installed | `.config/zed/` (removed on purpose 2026-07-22), `konsolerc`, `yakuakerc`, `katerc` and other rc files of removed apps | The program is gone. |
| Shell leftovers | `~/.bashrc`, `~/.bash_profile`, `~/.zprofile` | Tool written lines only (old NVM loader, Quartus path, duplicate `GDK_SCALE`). Your shell is zsh. |
| Tool caches and runtimes | `.cargo`, `.rustup`, `.npm`, `.bun`, `.yarn`, `.dotnet`, `.java`, `.android`, `.arduino15`, `.cache`, `.config/{go,configstore,dconf,pulse,gtk-*,Qt*,Trolltech.conf,matplotlib,marimo,astro,.wrangler,yay}` | Regenerated by the tools. |
| KDE rc files | `kdeglobals`, `kwinrc`, `plasma-*rc` and the rest | Not decided here: feature 7 picks the keys for `kde/allow.list`. |
| Owned by claude-config | `.config/systemd/user/{claude-ram-watch.service,hookgate-review.*}`, `.claude/`, `.config/hookgate`, `.config/21st`, `.config/opencode` | claude-config's own installer. |
| Loose links | `~/.local/bin/music` (points into `~/Music`), `pyside6-*` (pip user install), `f2py`, `numpy-config` (dropped pipx numpy) | Not programs you configure. |

### Install list

Profile `server` installs on both profiles. Names in backticks are package names.

**pacman, server**: `zsh` `git` `neovim` `stow` `starship` `fzf` `zoxide` `eza` `bat` `fd` `jq` `rsync` `wget` `unzip` `openssh` `git-delta` `github-cli` `difftastic` `btop` `duf` `dust` `hyperfine` `docker` `docker-compose` `mise`

**mise, server**: node 24 (from the mise config package, not a separate entry)

**pacman, desktop, Plasma**: `plasma-meta` (new, replaces the 58 Plasma packages listed under *Comes as a dependency*) `sddm-kcm` `plymouth-kcm` `breeze-plymouth` `plasma-sdk` `plasma-workspace-wallpapers` `kvantum`

**pacman, desktop, KDE apps**: `ark` `calligra` `colord-kde` `dolphin` `dolphin-plugins` `ffmpegthumbs` `filelight` `gwenview` `kalk` `kamera` `kamoso` `kcalc` `kdeconnect` `kdegraphics-thumbnailers` `kdenlive` `kdf` `kdialog` `kio-admin` `kio-extras` `kmix` `kolourpaint` `krecorder` `ktimer` `kwalletmanager` `markdownpart` `okular` `partitionmanager` `signon-kwallet-extension` `skanpage` `svgpart` `konversation` `ktorrent` `krdc` `kgpg` `kleopatra` `keysmith` `kio-gdrive` `kio-zeroconf` `kdenetwork-filesharing`

**pacman, desktop, terminal and dev**: `fastfetch` (desktop shell only, kept off servers by the scope) `alacritty` `ghostty` `tmux` `yazi` `tealdeer` `chafa` `viu` `wl-clipboard` `speedtest-cli` `7zip` `tree-sitter-cli` `perl-image-exiftool` `nodejs` `npm` `go` `python-pip` `python-pipx` `python-virtualenv` `python-matplotlib` `python-pandas` `python-scikit-learn` `python-ipywidgets` `jupyter-notebook` `uvicorn` `aws-cli-v2` `geckodriver` `postgresql` `ollama` `cloudflared` (new, replaces the downloaded binary) `uv` (new, replaces the downloaded binary) `git-filter-repo` (new, replaces the copied script)

**pacman, desktop, apps**: `firefox` `discord` `telegram-desktop` `signal-desktop` `obsidian` `libreoffice-fresh` `gimp` `inkscape` `obs-studio` `picard` `easyeffects` `mpv` `spotify-launcher` `steam` `proton-vpn-gtk-app` `bleachbit` `virt-manager` `qemu-full` `libvirt` `dnsmasq` `piper` `earlyoom` `fuse2` `libappindicator`

**pacman, desktop, network and hardware tools**: `nmap` `tcpdump` `wireshark-qt` `aircrack-ng` `arp-scan` `iw` `ethtool` `dhclient` `bluez-utils` `alsa-utils` `usbutils` `evtest` `android-tools` `arduino-cli` `esptool` `iverilog` `bpf`

**pacman, desktop, TeX**: `texlive-bibtexextra` `texlive-binextra` `texlive-fontsextra` `texlive-langspanish` `texlive-latex` `texlive-latexextra` `texlive-mathscience` `texlive-plaingeneric` `biber`

**pacman, desktop, fonts, themes, codecs**: `inter-font` `noto-fonts-cjk` `ttf-hack-nerd` `papirus-icon-theme` `xcursor-themes` `gst-plugins-ugly`

**pacman, desktop, hardware tagged**:
| Package | hw: |
|---|---|
| `amd-ucode` | AMD CPU |
| `vulkan-radeon` | AMD GPU |
| `lib32-vulkan-radeon` | AMD GPU |
| `asusctl` | ASUS ROG laptop |
| `rog-control-center` | ASUS ROG laptop |
| `openrgb` | RGB devices |
| `udev-hid-bpf` | Corsair K70 keyboard |
| `wacomtablet` | Wacom tablet |
| `keyd` | this laptop's arrow keys (config in `system/keyd`) |

**aur, desktop**: `yay` (bootstrap: installed first, from its git repo) `brave-bin` `claude-desktop-bin` `dirb` `ffuf` `figma-linux` `mendeley-reference-manager` `packettracer` `seclists` `visual-studio-code-bin` `zoom` `stripe-cli-bin` (new, replaces the downloaded binary) `howdy-git` (hw: IR camera for face login)

**flatpak, desktop** (flathub): `org.vinegarhq.Sober`

**pipx, desktop**: `yt-dlp` `spotdl` `rembg` `marimo` `instaloader` `aws-sam-cli`

### Not on the install list

**Comes as a dependency** (pulled by an entry above, so not listed):
- By plasma-meta: `aurorae` `bluedevil` `breeze` `breeze-gtk` `drkonqi` `flatpak-kcm` `kactivitymanagerd` `kde-cli-tools` `kde-gtk-config` `kdecoration` `kdeplasma-addons` `kglobalacceld` `kinfocenter` `kmenuedit` `knighttime` `kpipewire` `krdp` `kscreen` `kscreenlocker` `ksshaskpass` `ksystemstats` `kwallet-pam` `kwayland` `kwin` `kwrited` `layer-shell-qt` `libkscreen` `libksysguard` `libplasma` `milou` `ocean-sound-theme` `oxygen` `oxygen-sounds` `plasma-activities` `plasma-activities-stats` `plasma-browser-integration` `plasma-desktop` `plasma-disks` `plasma-firewall` `plasma-integration` `plasma-keyboard` `plasma-login-manager` `plasma-nm` `plasma-pa` `plasma-thunderbolt` `plasma-vault` `plasma-welcome` `plasma-workspace` `polkit-kde-agent` `powerdevil` `print-manager` `spectacle` `systemsettings` `xdg-desktop-portal-kde`
- Deeper Plasma deps: `breeze-cursors` (by breeze) `qqc2-breeze-style` (by plasma-integration) `plasma5support` (by plasma-desktop)
- By steam: `lib32-gcc-libs` `lib32-glibc` `libxcrypt-compat`
- By qemu-full: `edk2-ovmf`

plasma-meta also brings `discover` and `plasma-systemmonitor`, which are not installed today.

**Base reference** (installed by the Arch install itself; `dot` does not install them): `base` `base-devel` `linux` `linux-headers` `linux-firmware` `grub` `efibootmgr` `networkmanager` `sddm` `dkms` `nano`

**Dropped** (installed today, off the install list; pull one back by moving it up):
- KDE dev tools: `kdevelop` `kdevelop-php` `kdevelop-python` `kde-dev-scripts` `kde-dev-utils` `kdesdk-kio` `kdesdk-thumbnailers` `umbrello` `lokalize` `poxml` `kirigami-gallery` `kdebugsettings` `kompare` `kgraphviewer` `kimagemapeditor` `accessibility-inspector`
- Disc and audio: `k3b` `audex` `audiocd-kio` `kwave` `isoimagewriter` `skanlite`
- Small utilities: `kalarm` `kalm` `kbackup` `kcharselect` `kclock` `kcolorchooser` `kcron` `kfind` `kmag` `kmousetool` `kmouth` `kontrast` `kruler` `ksystemlog` `kjournald` `sweeper` `qrca` `keditbookmarks` `khelpcenter` `kde-inotify-survey`
- Other apps: `dbeaver` `mysql-workbench` `vlc` `vlc-plugins-extra` `drawio-desktop` `kget`
- X11 leftovers: `kwin-x11` `kgamma` `oxygen-cursors` (recommended: the session is Wayland; see rationale)
- Duplicate: pacman `yt-dlp` (the pipx copy is the one on your PATH)
- pipx `numpy` (only gave `f2py`; `python-numpy` comes with pandas and matplotlib)

### Owned elsewhere (installed, not by `dot`)

| Owner | Items |
|---|---|
| claude-config installer | claude CLI, `graphify` (pipx), `paper-search-mcp` and `zotero-mcp` (uv), `@21st-dev/cli` (npm), user units `claude-ram-watch` and `hookgate-review`, the `jjstack-plan` and `wf` links |
| work setup (outside this repo) | three pipx work tools |
| feature 7 | which KDE rc keys are kept |
| feature 13 | which server distros, and how the server list maps to their package names |

### Value sourcing

| Action | Value | Source |
|---|---|---|
| install list | whether a program is kept | usage evidence in rationale.md, then your prune answers (2026-10-11) |
| install list | source of an entry | `pacman -Si` repo for pacman, `yay -Si` for AUR, `flatpak list` origin, `pipx list` |
| install list | profile | your server set answer: core shell, git extras, system view, hyperfine, docker, mise |
| install list | `hw:` tag | the hardware the package drives (`pacman -Qi` description) |
| config list | files per package | the live files listed in rationale.md, minus state files |
| config list | profile | the program's install list profile (AC-5) |
| coverage check | the expected package set | `pacman -Qqe` on this machine |

**Key invariants**:
- A package name appears in exactly one of: install list, comes as a dependency, base reference, dropped.
- No credential file appears in the config list.
- A config package's profile never exceeds its program's profile.

**Security model**: public repo. Credentials are their own left behind group; the git package drops the global plaintext store helper; work tool names are not written here.

**Critical test scenarios**:
- Coverage: the check in *Build plan* ends with `300 packages, 0 not exactly once`. Remove one name from this file and it prints that name (mutation check). Verifies **AC-4**.
- Profiles: every server config package (`zsh`, `git`, `mise`, `nvim`, `starship`, `claude-config`) maps to a `server` install entry. Verifies **AC-5**.
- Git: the planned `.gitconfig` has no `[credential]` section with `helper = store` other than the gitlab.freedesktop.org one. Verifies **AC-7**.

## Build plan

This feature produces lists, not code; features 4, 5, 6, 9 and 10 build from them.

1. Run the coverage check below on this file and fix the lists until it ends with `0 not exactly once` (it did on 2026-10-11; removing `ghostty` made it print `ghostty: 0`). Satisfies **AC-3**, **AC-4**.
   ```bash
   spec=docs/specs/0002-program-inventory/index.md
   body=$(sed -n '/^### Install list/,/^### Owned elsewhere/p' "$spec" | grep -v -e '^\*\*pipx' -e '^\*\*flatpak')
   bad=0
   for p in $(pacman -Qqe); do
     n=$(grep -o -F "\`$p\`" <<<"$body" | wc -l)
     [ "$n" -ne 1 ] && { echo "$p: $n"; bad=$((bad + 1)); }
   done
   echo "$(pacman -Qqe | wc -l) packages, $bad not exactly once"
   ```
2. Cross check the config list profiles against the install list. Satisfies **AC-1**, **AC-5**, **AC-6**.
3. Record the scoped credential helper for feature 6. Satisfies **AC-7**.
4. You read the three lists, move anything you disagree with, and mark scope feature 2 done. Satisfies **AC-2**, **AC-8**.

## Consequences

**Positive**:
- Features 4 to 10 build from a fixed list; none of them decides membership again.
- A new desktop gets about 190 named entries instead of 312, and none of the never launched KDE apps.

**Negative / tradeoffs**:
- The usage evidence is partial: KDE's launch history only counts launches from the menu, KRunner and task manager, and zsh history misses programs started by other programs. A dropped program you need comes back by hand.
- `plasma-meta` follows Arch's idea of Plasma, so a new machine gets `discover` and `plasma-systemmonitor`, which this one lacks.
- The list is a snapshot of 2026-10-11; feature 10's sync check is what catches later installs.
- Hardware tags only inform; feature 10 decides how to ask.

**Neutral**:
- Feature 6 now covers git, mise, tealdeer, yt-dlp and easyeffects; yazi, btop and mpv (named in its scope row) have nothing to track.

## Follow-up

- [ ] Scope: update feature 6's row (git, mise, tealdeer, yt-dlp, easyeffects) and link features 5, 6 and 10 to this spec.
- [ ] Feature 6: remove the `zed='zeditor'` alias from `home/zsh/.zshrc` (Zed was removed on purpose).
- [ ] Feature 10: install `yay` before AUR entries, and remove the downloaded `cloudflared`, `stripe`, `uv`, `uvx`, `git-filter-repo` from `~/.local/bin` once the packages are in.
- [ ] Feature 10: on this machine, drop the pacman `yt-dlp`, the pipx `numpy` and the dropped KDE apps only when you choose to (this spec changes no installed package).
- [ ] Feature 13: map the server list to package names on the chosen server distros (`starship`, `mise`, `eza`, `difftastic` are not in every distro's repos).
- [ ] claude-config: confirm its installer covers the items listed as its own.
