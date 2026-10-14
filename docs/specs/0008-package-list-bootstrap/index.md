# 0008. Package list and bootstrap: plain list files and `dot bootstrap`

**Date**: 2026-10-14
**Status**: Proposed
**Paths:** `dot`, `packages/**`, `home/git/.gitconfig`, `profiles/server`, `tests/dot-status.sh`, `tests/server-profile.sh`, `tests/packages.sh`
**Builds**: [0002](../0002-program-inventory/index.md) install list and Follow-up, [0003](../0003-server-profile.md) package mapping and Follow-up. Feature 10.

## Summary

Spec 0002 wrote the install list as prose tables (every program you use, marked server or desktop, with its source: pacman, AUR, flatpak, pipx). Spec 0003 mapped the server half onto Debian and Ubuntu package names per release. This spec turns both into plain text files under `packages/` that `dot` reads, and adds `dot bootstrap <profile>`: on a fresh machine it installs everything on the list (asking once, showing the list first), sets up Oh My Zsh or the server's sparse git plugin, makes zsh your login shell, enables the services, then runs `dot install`. `dot status` and `dot sync` list any program installed since the lists were last reviewed.

## What you're agreeing to

- `packages/` holds your install list as plain files you can edit; nothing installs a program that is not in them.
- On a new machine: clone the repo, run `./dot bootstrap desktop` (or `server`), read the list it prints, answer once, and it installs, then links your configs.
- Hardware packages (AMD, ASUS, Corsair, Wacom, IR camera, keyd) are asked per hardware group, default no.
- Plasma is installed without Discover, System Monitor, Bigscreen and the X11 leftovers.
- `dot status` goes red when a program is installed but on no list, until you add it or mark it dropped.

Context, options and rationale: [rationale.md](rationale.md).

## Requirements

**User stories**:
- As the owner, I want a new desktop or server set up from one command, with every program I use and nothing I dropped.
- As the owner, I want to be told when I install something the list does not know about.

**Acceptance criteria**:
- **AC-1** (files): `packages/server` and `packages/desktop` hold one entry per line: `<source> <name> [hw:<tag>]`, `#` comments. Sources: `pacman`, `aur`, `flatpak`, `pipx`, `group` (a pacman group minus names given as `-<name>` after it), `service` (a systemd unit to enable). `packages/reviewed` lists names that are deliberately not installed (spec 0002's *Comes as a dependency*, *Base reference* and *Dropped*), one per line with a `#` section comment. `packages/server-apt.tsv` is 0003's mapping table as tab separated columns `tool arch apt D12 D13 U22 U24 U26`, each release cell `apt` or `mise` or `repo:docker` or `repo:mise`.
- **AC-2** (content): every entry of 0002's install list is in exactly one of `packages/server` or `packages/desktop` with its source and profile, `hw:` tags as 0002's table. Plasma is `group plasma -discover -plasma-systemmonitor -plasma-bigscreen -kwin-x11 -kgamma -oxygen-cursors -wacomtablet` (wacomtablet stays as its own `hw:wacom` line). The services line set: server `service docker`; desktop `service earlyoom`, `service keyd hw:keyd`, `service bluetooth`. `tests/packages.sh` runs 0002's coverage check against the files: every `pacman -Qqe` name on this machine appears exactly once across `packages/*` (a group member counts once through its group line, so it is not repeated as its own line or in `reviewed`; 0002's `sddm-kcm`, `plymouth-kcm`, `breeze-plymouth`, `plasma-sdk`, `plasma-workspace-wallpapers` and most of its *Comes as a dependency by plasma-meta* list are group members), and prints `<n> packages, <m> not exactly once`, with m = 0.
- **AC-3** (bootstrap command): `dot bootstrap <desktop|server> [-n]` needs only `bash`, `git` and `sudo` (or root). It reads `/etc/os-release`: Arch for both profiles; Debian 12/13 and Ubuntu 22.04/24.04/26.04 for `server` only (any other: exit 1 with the ID and VERSION_ID). It prints the plan (per source: the names; per `hw:` tag: the names), asks `install these? [y/N]` once, then one `hw` question per tag (default no). `-n` prints the plan and every command it would run, and changes nothing. No terminal and no `-n`: it prints the plan and exits 1.
- **AC-4** (Arch order): pacman (`sudo pacman -S --needed` the pacman entries plus `pacman -Sgq <group>` minus its excludes), then `yay` when missing (clone `https://aur.archlinux.org/yay-bin.git`, `makepkg -si`), then `yay -S --needed` the AUR entries, then flatpak (`flatpak remote-add --if-not-exists flathub ...`, `flatpak install -y flathub <ids>`), then `pipx install` each pipx entry not yet in `pipx list --short`.
- **AC-5** (Debian and Ubuntu): for each `server-apt.tsv` row, the release column picks `apt` (installed with `apt-get install -y`), `repo:docker` or `repo:mise` (vendor repo added with its key in `/etc/apt/keyrings/` and `signed-by`, then installed), or `mise` (written to `~/.config/mise/conf.d/server.toml`, never to the tracked mise config, then `mise install`). A tool in neither apt nor the mise registry prints `bootstrap: <tool> skipped, not packaged for <release>` and does not fail. zoxide on D12 and U22, and gh on U22, are `mise` (0003 Follow-up version floors).
- **AC-6** (shell and services): desktop: clone Oh My Zsh and its three plugins (autosuggestions, syntax highlighting, completions) as `install.sh` does today; server: the sparse `ohmyzsh/ohmyzsh` checkout at `~/.local/share/omz-git` with `lib/git.zsh` and `plugins/git/` (0003), plus the two distro plugin packages. Both: `chsh -s "$(command -v zsh)"` when the login shell is not zsh, add the user to the `docker` group when docker was installed, `sudo systemctl enable --now <unit>` for each `service` entry whose package is installed. Then it runs `dot install <profile>` (passing `-n` through).
- **AC-7** (unreviewed check): on Arch, `dot status` lists each name in `pacman -Qqe`, `pipx list --short` (first word) and `flatpak list --app --columns=application` that is in no `packages/*` file as `package: <name> is installed but on no list`, counted as a problem. `dot sync` prints the same lines without failing. Off Arch the check is skipped.
- **AC-8** (gh helper): `home/git/.gitconfig` uses `helper = !gh auth git-credential` (found on `PATH`) for github.com and gist.github.com, so a mise installed gh works.
- **AC-9** (tests): `tests/server-profile.sh` replaces its hand written package step with `dot bootstrap server` (as root, no sudo) in all six images and keeps its shell checks; `tests/dot-status.sh` covers `bootstrap -n` on a fake `/etc/os-release` (`DOT_OS_RELEASE` override) for Arch desktop, Debian 12 server, and an unknown ID (exit 1), the AC-1 line parser (group excludes, `hw:` tags, a bad line reported), and the unreviewed check with stand-in `pacman`, `pipx` and `flatpak` commands on `PATH`.
- **AC-10** (no old installer needed): after this feature, nothing in `dot bootstrap` or `dot install` calls `install.sh`; `install.sh` is left for feature 12 to delete.

## Feature design

**Files**:
```
packages/server            # both profiles
packages/desktop           # desktop extras (Arch only)
packages/reviewed          # dependencies, base, dropped: known, not installed by dot
packages/server-apt.tsv    # 0003 mapping, one row per tool
```
Example lines: `pacman zsh`, `group plasma -discover -plasma-systemmonitor ...`, `aur brave-bin`, `aur howdy-git hw:ir-camera`, `pacman amd-ucode hw:amd-cpu`, `flatpak org.vinegarhq.Sober`, `pipx yt-dlp`, `service earlyoom`.

**Value sourcing**:

| Action | Value | Source |
|---|---|---|
| bootstrap | which programs | `packages/server`, plus `packages/desktop` for desktop |
| bootstrap | Debian/Ubuntu names and fallbacks | `packages/server-apt.tsv`, column from `/etc/os-release` `ID` and `VERSION_ID` |
| bootstrap | hardware groups | `hw:` tags (0002 table) |
| bootstrap | Plasma members | `pacman -Sgq plasma` at run time, minus the excludes on the line |
| bootstrap | services | `service` lines |
| status, sync | installed programs | `pacman -Qqe`, `pipx list --short`, `flatpak list --app --columns=application` |
| status, sync | known programs | every name in `packages/*` (group lines: the group's members minus excludes) |
| tests | os-release | `DOT_OS_RELEASE` (test only) |

**Key invariants**:
- Bootstrap installs only names from `packages/*`.
- Nothing is removed by bootstrap (dropped packages on an old machine stay; 0002 Follow-up).
- The tracked mise config is never written by bootstrap.
- `sudo` is called only after the single yes.

**Security model**: two vendor apt repos (Docker, mise) with pinned keyrings (0003). The AUR helper is built from the AUR's git with `makepkg` as your user. No package list holds a secret.

**Critical test scenarios**:
- Six container images, `dot bootstrap server`, then 0003's shell checks. Verifies **AC-3**, **AC-5**, **AC-6**, **AC-9**.
- Coverage on this desktop: 0 not exactly once; delete one line and the name is printed (mutation check). Verifies **AC-2**.
- `dot bootstrap desktop -n` on this desktop prints the plan with Plasma without Discover. Verifies **AC-3**, **AC-4**.
- Stand-in `pacman -Qqe` with one extra name: `dot status` names it and exits 1. Verifies **AC-7**.

## Build plan

1. Write `packages/*` from 0002 and 0003; `tests/packages.sh` coverage check to 0. Satisfies **AC-1**, **AC-2**.
2. Line parser and `bootstrap -n` plan output, os-release detection, tests. Satisfies **AC-3**, **AC-9**.
3. Arch install path (pacman, group, yay, AUR, flatpak, pipx). Satisfies **AC-4**.
4. apt path (mapping, vendor repos, mise fallback). Satisfies **AC-5**.
5. Shell, chsh, docker group, services, then `dot install`. Satisfies **AC-6**.
6. Switch `tests/server-profile.sh` to `dot bootstrap server`; run all six images. Satisfies **AC-9**.
7. Unreviewed check in status and sync. Satisfies **AC-7**.
8. gh helper on `PATH`. Satisfies **AC-8**.
9. You run `dot bootstrap desktop -n` here and read the plan; a real desktop bootstrap waits for a new machine or a VM. Waits on you.

## Probes

| Probe | Command | Result |
|---|---|---|
| P1 `--ignore` with a group | `pacman -Sp --print-format %n --needed plasma --ignore discover --ignore plasma-systemmonitor` | ran 2026-10-14 (read only): still lists `discover` and `plasma-systemmonitor`, so `--ignore` cannot be trusted under `--noconfirm`; the group is expanded and filtered instead (AC-4) |
| P2 group members | `pacman -Sg plasma` | ran 2026-10-14: 71 members incl. `plasma-bigscreen`, `kwin-x11`, `kgamma`, `oxygen-cursors`, `wacomtablet` |
| P3 server images | `tests/server-profile.sh` after step 6 | build runs it (containers only, needs docker) |
| P4 desktop bootstrap for real | on a VM or new machine | you |

## Consequences

**Positive**:
- One command per machine; the list is the truth and is checked against what is installed.

**Negative / tradeoffs**:
- `dot status` is red after any install until you file the new name.
- The desktop path is only dry run tested until a real new machine (P4).

**Neutral**:
- `dot` gains a `bootstrap` command; `install.sh` is unused and goes with feature 12.

## Follow-up

- [ ] On this machine, remove the downloaded `cloudflared`, `stripe`, `uv`, `uvx`, `git-filter-repo` from `~/.local/bin` once their packages are in (0002 Follow-up; deletion is yours).
- [ ] 0002 Follow-up: drop pacman `yt-dlp`, pipx `numpy` and the dropped KDE apps here only when you choose to.
- [ ] Spec 0011 (claude-config submodule) adds its own installer call; bootstrap does not install Claude tools.
