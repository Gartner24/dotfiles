# 0003. Server profile: distros, zsh split and package mapping

**Date**: 2026-10-11
**Status**: Proposed

## Summary

Servers (VPS, VDS, headless boxes) run Arch, Debian 12 or newer, or Ubuntu 22.04 or newer. The shared `.zshrc` keeps only what a server needs. Everything desktop related (Oh My Zsh, fastfetch, tips, KDE and clipboard helpers, Claude helpers) moves to a new `zsh-desktop` package that only the desktop profile links. Servers skip the Oh My Zsh framework. They load the two zsh plugins straight from distro packages and only its git aliases file from a small sparse checkout, for a shell that starts in half the desktop time or less. This spec also records which package name each server tool has on each distro, and that mise fills the gaps. Feature 10 builds the installer from that table.

## Context

Feature 13 asks for a lean shell on servers. Today one `.zshrc` (in the `zsh` package, server profile) carries everything: Oh My Zsh, fastfetch, the shortcuts panel, the tldr tip, KDE `nosleep`, `wl-copy` helpers, `claude-fb`, Arch only blocks, and paths into `/home/santiago`. A server linking it gets all of that, and pays Oh My Zsh's load time on every shell.

The repo already models profiles as package lists (spec 0001 AC-3): `profiles/server` holds `zsh`, `starship`, `nvim`, and the desktop profile adds its own list on top. The `.zshrc` has no way to know which profile it runs under, and spec 0001 kept runtime profile checks out of configs.

Servers mostly run stock VPS images, which means Debian and Ubuntu, not Arch. Spec 0002 marked the server install list with Arch names. Several of those tools are missing or too old in Debian 12, Ubuntu 22.04 and 24.04 (starship, eza, nvim 0.10+). Debian also renames two binaries (`bat` is `batcat`, `fd` is `fdfind`), so the current aliases and fzf settings break there. The current `alias cd='z'` is also unconditional, so a box without zoxide gets a broken `cd`.

## Requirements

**User stories**:
- As the owner, I want `dot install server` on a stock Debian, Ubuntu or Arch box to give me my shell without any desktop baggage.
- As the owner, I want a server shell that starts noticeably faster than my desktop shell, measured, not guessed.
- As the owner, I want one table that says where every server tool comes from on each distro, so feature 10 builds the installer without asking again.

**Acceptance criteria**:
- **AC-1**: Supported server systems are Arch, Debian 12 and 13, Ubuntu 22.04, 24.04 and 26.04. `dot install server` links the server packages without error on each one (checked in containers, AC-11).
- **AC-2**: The shared `home/zsh/.zshrc` sources config files in two steps, each sorted, with a missing folder staying silent. Step one sources `~/.config/zsh/conf.d/early/*.zsh` where Oh My Zsh loads today. Step two sources `~/.config/zsh/conf.d/*.zsh` after the fzf block and before the server plugin step. A new package `home/zsh-desktop/`, listed in `profiles/desktop`, holds `.config/zsh/conf.d/early/omz.zsh` (Oh My Zsh setup with its plugins, nothing else) and `.config/zsh/conf.d/desktop.zsh`. These move from the shared file to `desktop.zsh`: `_is_top_shell` and the fastfetch, shortcuts panel and tldr tip startup output, terminal emulator detection, GUI only aliases, the Arch Quartus block, `clipclear`, `copykey`, `nosleep`, `claude-fb`, `fixall`, `wtclean`, the yazi `y` function, the bun, claude-mem and opencode lines, `CHROME_PATH`, the cargo PATH line, and the Claude session step of `freeram`. History, PATH, EDITOR, telemetry, mise, zoxide, fzf, starship, the tool aliases, `freeram` (memory steps) and `up` stay shared.
- **AC-3**: When Oh My Zsh is not loaded after the early step (`(( $+functions[omz] ))` is false), the shared file runs `compinit` once. Right after that, it sources `lib/git.zsh` and then `plugins/git/git.plugin.zsh` from a sparse checkout of Oh My Zsh at `~/.local/share/omz-git`, holding only those two paths. Then `gst`, `gco` and the other git aliases, and `git_current_branch`, work on servers too. At the very end, it sources zsh-autosuggestions and then zsh-syntax-highlighting from the distro package paths: Arch `/usr/share/zsh/plugins/<name>/<name>.zsh`, Debian/Ubuntu `/usr/share/<name>/<name>.zsh`. Any missing file (the checkout or a plugin) is skipped silently.
- **AC-4**: Every tool alias (`cat`, `ls`, `ll`, `la`, `lt`, `ltd`, `top`, `htop`, `cd`) is defined only when its tool is on PATH, so a missing tool never shadows a builtin. `cat` and the fzf commands use `bat` or else `batcat`, and `fd` or else `fdfind`. fzf key bindings and completion load from the Arch path (`/usr/share/fzf/`) or else the Debian path (`/usr/share/doc/fzf/examples/`).
- **AC-5**: `freeram` stays shared and does its memory steps on any system. Its Claude stale session step runs only when `_freeram_claude` is defined (by `desktop.zsh`). Commands that need root use `sudo` only when `EUID` is not 0.
- **AC-6**: `up` stays shared. With `yay` on PATH, it behaves as today (`yay -Syu`, then flatpak, then the kernel module reboot notice). Otherwise, with `apt-get` on PATH, it runs `apt-get update` and `apt-get upgrade`, then `mise upgrade` when mise is present, and prints a reboot notice when `/var/run/reboot-required` exists. `sudo` only when `EUID` is not 0. With neither, it prints that it found no supported package manager and returns 1.
- **AC-7**: After `dot install server`, no link in `$HOME` points into a desktop package (`tmux`, `ghostty`, `alacritty`, `bin-desktop`, `zsh-desktop`), no system folder (`keyd`) is copied, and the `kde-theme` submodule is not initialized.
- **AC-8**: In the same `archlinux` container, `hyperfine --warmup 3 --runs 20 'zsh -i -c exit'` with the server setup has a mean of at most 50% of the desktop setup's mean. Server setup means `zsh` and `starship` linked, with the two plugin packages installed and the `~/.local/share/omz-git` sparse checkout in place. Desktop setup is the same, plus `zsh-desktop` linked and Oh My Zsh with its three plugins cloned. fastfetch and tealdeer are installed in neither, so the ratio measures config, not those tools.
- **AC-9**: The mapping table below lists every server entry from spec 0002 plus `zsh-autosuggestions` and `zsh-syntax-highlighting`, with the Arch name, the apt name, and the source per supported release. Every apt row marked `to verify` is checked with `apt-cache policy` in that release's container and updated (version, or `mise` when missing or too old) before this feature is done.
- **AC-10**: In a `debian:12` container with starship, eza and neovim installed through mise from a machine local mise config file (not the tracked `~/.config/mise/config.toml`), a new interactive shell shows the starship prompt, `ls` resolves to eza, and `nvim --version` reports 0.10 or newer.
- **AC-11**: `tests/server-profile.sh` runs the checks for AC-1, AC-3, AC-4, AC-7, AC-8 and AC-10 in `archlinux`, `debian:12`, `debian:13`, `ubuntu:22.04`, `ubuntu:24.04` and `ubuntu:26.04` containers, never touches the real `$HOME` or repo, prints each failure, and exits non zero on any. Without docker, it says so and exits 2.
- **AC-12**: On the desktop, run three captures in a new interactive shell, in the same terminal, before the split and again after `dot install desktop`: the full `alias` output, the full `functions` output (names and bodies), and `print -l $path`. The two sets must match exactly, except for these intended changes: the `freeram` and `up` bodies, and the new `_freeram_claude`.

## Options considered

### Option 1: Desktop package adds a `conf.d` file

The shared `.zshrc` sources `~/.config/zsh/conf.d/early/*.zsh` and later `~/.config/zsh/conf.d/*.zsh`, and a `zsh-desktop` package (desktop list only) drops its files there.

**Pros**: profile choice stays in the lists, as in spec 0001. No runtime profile checks. Adding a desktop only bit means editing one file.
**Cons**: one more package. A desktop that pulls this change but skips `dot install desktop` quietly loses its desktop bits until it relinks.

### Option 2: One file with runtime guards

Keep one `.zshrc` and wrap desktop blocks in checks (read `.dot-profile`, or test `$WAYLAND_DISPLAY`).

**Pros**: no new package. Everything stays in one place.
**Cons**: every shell pays for the checks. A display check is wrong over SSH to the desktop. Reading `.dot-profile` ties the shell to the repo path.

### Option 3: Two full `.zshrc` files

`zsh` for desktop and `zsh-server` for servers, each a complete file.

**Pros**: each file reads straight through.
**Cons**: history, aliases and PATH are duplicated and drift apart. Two packages would own the same target file, which spec 0001 forbids.

**Related choices made in the same conversation**: servers drop the Oh My Zsh framework. They keep the two plugins from distro packages, plus its git aliases from a sparse checkout, so muscle memory is the same on both. Keeping the full framework would cost startup time, and dropping it everywhere would change the desktop shell too. Tools a release lacks come from mise (vendor apt repos per tool mean more keys to trust, curl | sh is the riskiest option, and skipping tools leaves gaps). mise itself and docker come from their signed vendor apt repos.

## Decision

**Chosen option**: Option 1: Desktop package adds a `conf.d` file.

Servers support Arch, Debian 12+ and Ubuntu 22.04+. The `.zshrc` splits into a shared `zsh` package and a desktop only `zsh-desktop` package. Servers skip the Oh My Zsh framework, source the two plugins from distro packages, and load its git aliases from a sparse checkout. This spec owns the per distro mapping table, and feature 10 builds the installer that reads it.

## Rationale

The force that settles it is spec 0001's model: a profile is a list, a program is a folder (basis: spec 0001 AC-3, AGENTS.md rules). Option 1 is the only one that keeps profile choice in the lists, so the shell never asks which machine it is on. Dropping Oh My Zsh is where the speed comes from. Its framework load is the largest part of startup. What you actually rely on is two plugins every distro packages and one git aliases file, all plain zsh files that load without the framework (basis: measure before optimising, AC-8 measures it).

Debian and Ubuntu cover almost every VPS image, and Arch covers the boxes you build yourself. A table in this spec, not a file, keeps the install file format with feature 10 as spec 0002 left it (basis: spec 0002 Follow-up). mise is already on the server list and installs prebuilt binaries into your home folder without sudo, so it fills every gap with one tool. Signed vendor repos for mise and docker match how apt manages everything else, without piped scripts.

## Feature design

**Shell layout**:
```
home/zsh/.zshrc                                       # shared, server profile
home/zsh-desktop/.config/zsh/conf.d/early/omz.zsh     # desktop: Oh My Zsh only
home/zsh-desktop/.config/zsh/conf.d/desktop.zsh       # desktop: everything else
~/.local/share/omz-git/{lib/git.zsh,plugins/git/}     # server: sparse checkout, not in the repo
```
Order in the shared `.zshrc`: history, `conf.d/early` loop (desktop loads Oh My Zsh here), then when Oh My Zsh is absent `compinit` and the sparse git files, PATH, editor, telemetry, mise, guarded aliases, `freeram`, `up`, starship, zoxide, fzf, `conf.d` loop (desktop rest, keeping its current order after the shared parts), and last the two plugins when Oh My Zsh is absent.

**Data model sketch**: no stored data. Three inputs: the `conf.d` folder contents (decided by which packages are linked), the mapping table below, and `/etc/os-release` (`ID`, `VERSION_ID`), which feature 10 reads to pick a table column.

**Package mapping** (server install list from spec 0002, plus the two plugins). Releases: D12, D13 Debian; U22, U24, U26 Ubuntu. `apt` = distro package with the apt name. `to verify` rows get checked in build task 6 (AC-9). Confirmed rows come from the package search pages in References.

| Tool | Arch | apt name | D12 | D13 | U22 | U24 | U26 |
|---|---|---|---|---|---|---|---|
| zsh | `zsh` | `zsh` | apt, to verify | apt, to verify | apt, to verify | apt, to verify | apt, to verify |
| git | `git` | `git` | apt, to verify | same | same | same | same |
| neovim | `neovim` | `neovim` | mise (apt 0.7.2) | apt 0.10.4 | mise (apt 0.6.1) | mise (apt 0.9.5) | apt 0.11.6 |
| stow | `stow` | `stow` | apt, to verify | same | same | same | same |
| starship | `starship` | `starship` | mise (missing) | apt 1.22.1 | mise (missing) | mise (missing) | apt 1.22.1 |
| fzf | `fzf` | `fzf` | apt, to verify | same | same | same | same |
| zoxide | `zoxide` | `zoxide` | apt, to verify | same | same | same | same |
| eza | `eza` | `eza` | mise (missing) | apt 0.21.0 | mise (missing) | apt 0.18.2 | apt 0.23.4 |
| bat | `bat` | `bat` (binary `batcat`) | apt 0.22.1 | apt 0.25.0 | apt 0.19.0 | apt 0.24.0 | apt 0.25.0 |
| fd | `fd` | `fd-find` (binary `fdfind`) | apt, to verify | same | same | same | same |
| jq | `jq` | `jq` | apt, to verify | same | same | same | same |
| rsync | `rsync` | `rsync` | apt, to verify | same | same | same | same |
| wget | `wget` | `wget` | apt, to verify | same | same | same | same |
| unzip | `unzip` | `unzip` | apt, to verify | same | same | same | same |
| openssh | `openssh` | `openssh-client` | apt, to verify | same | same | same | same |
| git-delta | `git-delta` | `git-delta` | to verify, else mise | same | same | same | same |
| github-cli | `github-cli` | `gh` | to verify, else mise | same | same | same | same |
| difftastic | `difftastic` | `difftastic` | to verify, else mise | same | same | same | same |
| btop | `btop` | `btop` | to verify, else mise | same | same | same | same |
| duf | `duf` | `duf` | to verify, else mise | same | same | same | same |
| dust | `dust` | `du-dust` | to verify, else mise | same | same | same | same |
| hyperfine | `hyperfine` | `hyperfine` | to verify, else mise | same | same | same | same |
| docker | `docker`, `docker-compose` | `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` | Docker apt repo | same | same | same | same |
| mise | `mise` | `mise` | mise apt repo, unless the distro has it (to verify) | same | same | same | same |
| zsh-autosuggestions | `zsh-autosuggestions` | `zsh-autosuggestions` | apt, to verify | same | same | same | same |
| zsh-syntax-highlighting | `zsh-syntax-highlighting` | `zsh-syntax-highlighting` | apt, to verify | same | same | same | same |

**Rules feature 10 builds** (decided here, built there):
- A tool marked `mise` for a release goes into a machine local mise config file (for example `~/.config/mise/conf.d/server.toml`), never into the tracked `.config/mise/config.toml`, which both profiles share.
- A tool that is neither in apt nor in the mise registry is skipped with a printed note, never a failed install.
- mise and docker repos are added with their signing keys under `/etc/apt/keyrings/` and `signed-by`.

**Value sourcing**:
| Action | Value | Source |
|---|---|---|
| shell start | which extra files load | `~/.config/zsh/conf.d/early/*.zsh` and `~/.config/zsh/conf.d/*.zsh`, present only when `zsh-desktop` is linked (`profiles/desktop`) |
| shell start | whether to run the server plugin path | `$+functions[omz]` after the early step |
| shell start | git aliases on servers | `~/.local/share/omz-git/lib/git.zsh` and `plugins/git/git.plugin.zsh`, a sparse checkout of `ohmyzsh/ohmyzsh` that feature 10 creates |
| shell start | plugin file paths | the fixed distro paths in AC-3 |
| aliases, fzf | bat and fd binary names | `$commands[bat]` else `$commands[batcat]`; `$commands[fd]` else `$commands[fdfind]` |
| `up` | which branch | `$commands[yay]`, then `$commands[apt-get]` |
| `up`, `freeram` | sudo prefix | `EUID` |
| `up` | reboot needed | Arch: `/usr/lib/modules/$(uname -r)` missing; apt: `/var/run/reboot-required` exists |
| `freeram` | run the Claude step | `$+functions[_freeram_claude]` |
| AC-8 | the ratio | hyperfine means of both setups, same container |
| AC-9 | apt versions | `apt-cache policy <name>` in each release container |
| feature 10 | which table column | `/etc/os-release` `ID` and `VERSION_ID` |

**Key invariants**:
- No file in `home/zsh/` references a desktop only program, GUI variable or `/home/santiago` path.
- `conf.d/early/omz.zsh` is the only place the full Oh My Zsh framework is loaded. Servers load only `lib/git.zsh` and the git plugin from it.
- Nothing installed by the mise fallback is written to a tracked file.

**Security model**: no secrets or credentials. Two signed vendor apt repos (Docker, mise) become trusted package sources on Debian and Ubuntu servers. Nothing personal moves into the server path. The `/home/santiago` paths stay in `desktop.zsh`, as public as they are today.

**Configuration required**: none.

**Critical test scenarios**:
- Happy path: `debian:12` container, `dot install server`, then a new shell has autosuggestions, highlighting, the `gst` alias, the starship prompt via mise, and working `cd`, `cat`, `ls`. Verifies **AC-1**, **AC-3**, **AC-4**, **AC-10**.
- Isolation: after `dot install server`, no link points into a desktop package and `kde-theme` stays uninitialized. Verifies **AC-7**.
- Speed: hyperfine ratio of at most 0.5 in `archlinux`. Verifies **AC-8**.
- Regression: the desktop aliases, function bodies and `$PATH` are unchanged after the split, apart from the intended changes. Verifies **AC-12**.
- Failure case: a container without zoxide, eza or bat still gets a working `cd`, `ls` and `cat`. Verifies **AC-4**.
- Root: `up` and `freeram` as root on a box without sudo run without calling sudo. Verifies **AC-5**, **AC-6**.

## Build plan

Tracer Bullet: prove the split on the real desktop first, then run one container end to end, then widen to every release.

1. Capture the desktop `alias`, `functions` and `$path` output. Create `home/zsh-desktop/` with `conf.d/early/omz.zsh` and `conf.d/desktop.zsh`, move the AC-2 sections, add both loops, add `zsh-desktop` to `profiles/desktop`, run `dot install desktop`, and compare the captures. Satisfies **AC-2**, **AC-12**.
2. Add the server path: `compinit` and the sparse git files when Oh My Zsh is absent, and the plugins at the end. Satisfies **AC-3**.
3. Write `tests/server-profile.sh` for `archlinux` only: install the server packages, create the sparse checkout, run `dot install server`, check the links, the `gst` alias and the hyperfine ratio. Satisfies **AC-3**, **AC-7**, **AC-8**, **AC-11**.
4. Guard the tool aliases, add the `batcat`/`fdfind` fallback and the Debian fzf path. Extend the test to `debian:12`, `debian:13`, `ubuntu:22.04`, `ubuntu:24.04` and `ubuntu:26.04`. Satisfies **AC-1**, **AC-4**, **AC-11**.
5. Split `freeram` (`_freeram_claude` into `desktop.zsh`) and `up` (apt branch, root aware sudo). Satisfies **AC-5**, **AC-6**.
6. Run `apt-cache policy` for every `to verify` row in each release container, and update the mapping table in this spec. Satisfies **AC-9**.
7. Add the mise fallback check to the `debian:12` run (machine local mise config with starship, eza, neovim). Satisfies **AC-10**, **AC-11**.

## Migration plan

**Strategy**: no data migration. One commit moves the desktop sections.
**Phases**: 1. Split and relink on the desktop (task 1). 2. Server path and tests (tasks 2 to 7).
**Rollback**: revert the split commit, then `stow -D -d home -t ~ zsh-desktop`.
**Risks**: a desktop that pulls the change without running `dot install desktop` loses its desktop shell bits until relinked. The server plugin path then takes over, so the shell still works.

## Consequences

**Positive**:
- A stock VPS gets your shell with one `dot install server`, minus desktop baggage.
- Startup speed is a measured, repeatable number, not a feeling.
- Feature 10 gets a complete source table and builds one installer for both profiles.

**Negative / tradeoffs**:
- Servers depend on a sparse checkout of Oh My Zsh outside the repo for the git aliases. It updates only when it's pulled, and `lib/git.zsh` must stay compatible with the plugin file if upstream changes either.
- Two vendor repos (Docker, mise) to trust and keep keys for on Debian and Ubuntu.
- mise installed tools on older releases update through `mise upgrade`, not apt, so `up` covers both.
- The container test needs docker and pulls six images, so it's slower than `tests/dot-status.sh`.

**Neutral**:
- One new package, `zsh-desktop`, in `profiles/desktop`.
- `install.sh` still clones Oh My Zsh everywhere until features 10 and 12 replace it.

## Follow-up

- [ ] Feature 10: install the full Oh My Zsh and its three plugins only on the desktop profile. Servers get the two distro plugin packages plus a sparse checkout of `ohmyzsh/ohmyzsh` at `~/.local/share/omz-git` holding only `lib/git.zsh` and `plugins/git/`.
- [ ] Feature 10: set zsh as the login shell (`chsh`) in the bootstrap, since stock servers default to bash.
- [ ] Spec 0001 AC-16: when claude-config lands in `dot`, add a headless `dot install server -n` run to `tests/server-profile.sh` (its checks need node, python3 and jq). This closes spec 0001's feature 13 Follow-up together with the stow row in the table.

## References

**Project sources**:
- `AGENTS.md`, rules for the new layout (one package per program, profiles as lists)
- Spec 0001, AC-3, AC-4, AC-13, AC-16 and its feature 13 Follow-up
- Spec 0002, the server install list and its feature 13 Follow-up
- `docs/scope/scope.md`, feature 13 and the 2026-10-11 decisions (no fastfetch, tips, shortcut panels or tmux on servers)

**Practices & standards**:
- Measure before optimising (hyperfine ratio on the same machine)
- Signed vendor apt repos (`signed-by` keyrings) over piped install scripts

**Links**:
- Debian neovim: https://packages.debian.org/search?keywords=neovim
- Ubuntu neovim: https://packages.ubuntu.com/search?keywords=neovim
- Debian eza: https://packages.debian.org/search?keywords=eza
- Ubuntu eza: https://packages.ubuntu.com/search?keywords=eza
- Debian starship: https://packages.debian.org/search?keywords=starship
- Ubuntu starship: https://packages.ubuntu.com/search?keywords=starship
- Debian bat: https://packages.debian.org/search?keywords=bat
- Ubuntu bat: https://packages.ubuntu.com/search?keywords=bat
