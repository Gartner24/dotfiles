# 0001. Rationale: repo layout and linking method

## Context

Your dotfiles repo mirrors `$HOME` paths at its root (`.zshrc`, `.config/ghostty/config`, `.local/bin/...`), and `install.sh` creates each symlink with its own `ln -s` line. Anything not listed there is not installed, and `sync-to-github.sh` copies four hardcoded files and then runs `git add .`, so anything untracked in the repo is published to a public remote. Some homes are already links (`.zshrc`, `.tmux.conf`, the ghostty config, `tmux-zen`, the Mac Dock); others are not (`~/.config/alacritty/alacritty.toml` is a real file, `~/.config/nvim` is a standalone clone with 1 local commit and 2 modified files).

The restructure (scope, 2026-10-11) wants one folder per program, a desktop profile and a lean server profile, system files from `/etc`, your full KDE setup, and a public repo that never carries personal state. Those goals pull against each other in three places. Programs that write state next to their config can leak it into a repo that links whole folders. KDE writes recent files, window geometry and device names into the same rc files that hold your shortcuts and rules; a check on 2026-10-11 confirmed `kwriteconfig6` writes through a symlink and keeps it, so linking works mechanically and the problem is purely the state it writes. And files under `/etc` are read by root, sometimes before `/home` is available.

Without a decision, each slice (zsh, terminals, KDE, system files) would invent its own placement and linking, and the deny mechanism would be whatever the first slice needed.

## Options considered

### Option 1: GNU Stow packages, plus copy paths for system and KDE files

Each program is a folder under `home/` that mirrors `~`; `stow --no-folding` links its files. `/etc` files and KDE rc files are copied (diff first, or through a group allow list and the deny list). Profiles are plain lists. (basis: GNU Stow manual, packages and `--no-folding`)

**Pros**:
- The folder per program layout you chose is exactly a stow package; no translation layer.
- Linked edits are live in the repo, so sync for most files is just a scoped commit.
- Stow is small, decades old, and packaged on Arch, Debian, Ubuntu and Fedora; dry run is built in.

**Cons**:
- A new dependency on every machine.
- Profiles, system files and KDE filtering are your own code in `dot`, not features of the tool.

### Option 2: chezmoi

chezmoi keeps a source directory and copies (or templates) files into place, with built in machine specific templates, encrypted secrets and an apply step.

**Pros**:
- Profiles and per machine differences are first class (templates).
- Secrets support is built in.

**Cons**:
- Source files are renamed (`dot_zshrc`, `private_dot_config`), which breaks the "folder per program, readable by eye" goal.
- Every edit needs `chezmoi edit` or a re add, and drift is the default state.
- A heavier tool to learn for what are mostly plain files.

### Option 3: own bash linker with a manifest

Keep `ln -s` in a script, driven by a manifest file that maps repo paths to home paths.

**Pros**:
- No new tool.
- Full control.

**Cons**:
- Conflict handling, dry run, unlinking and broken link detection are all yours to write and test, which is what stow already does.
- The current `install.sh` is this approach, and it drifted (NVM, Ubuntu path, missing links).

### Option 4: bare repo with home as the worktree (yadm style)

The repo's worktree is `~` itself; files are tracked in place.

**Pros**:
- No links at all.

**Cons**:
- No per program folders, which contradicts the layout you chose.
- Every `git status` in `~` sees your whole home; one wrong add publishes it.

## Rationale

Option 1 wins because the layout decision (a folder per program, profiles as membership) is already the stow model, so stow adds the least new concept for the most mechanism: linking, unlinking, conflict detection and dry run. chezmoi solves profiles and secrets well, but at the cost of renamed files and an apply loop, and your repo has no secrets to template (the deny list keeps them out instead). The own linker option is the current state, and its drift is the reason for this restructure.

Stow alone is wrong for two file groups, and the decision says so explicitly instead of forcing them through it. `/etc` files are copied because a root read config that resolves into a user owned file lets a user edit change system behavior and can fail at boot. KDE rc files are copied through a key level allow list because linking would push the state KDE writes into those files straight into the public repo. Key level, not group level: an allow list fails safe (a key nobody named cannot leak), while a group list leaks whatever else KDE puts in that group (device names under `[Libinput]`) unless a deny pattern happens to catch it. It also lets `kreadconfig6` and `kwriteconfig6` do the parsing, instead of hand written code for nested `[A][B]` groups. Your custom KDE look goes further: a published Global Theme repo with credits, which also gives others a way to install it. A Global Theme cannot hold shortcuts, window rules, input or power settings, so those stay as filtered copies here. (basis: KDE Plasma look and feel package docs)

Inside the stow choice: `--no-folding` so no program can write new files into the repo through a folder link; back up then link instead of `--adopt`, because adopt overwrites the repo copy with whatever is in `~`; one deny list enforced by a `pre-commit` hook on added lines (so manual commits are checked too, and an old line already in history does not block every later commit), and by `dot sync` before a live `/etc` file is copied back. (basis: GNU Stow manual, `--adopt`; git `core.hooksPath`)

Calls made without asking (smaller details):
- **Profile of a machine**: an explicit argument to `dot install`, saved in a gitignored `.dot-profile`. Runner up: detect a GUI from `$DISPLAY`, which gives the wrong answer for a desktop reached over SSH.
- **KDE allow list format**: one `kde/allow.list`, `<rcfile> <Group> <Key>` per line (set after the cross check, replacing a group level list). Runner up: one allow file per rc file, more files for no gain at this size.
- **KDE restore**: write each key with `kwriteconfig6`, then ask you to log out, because kglobalaccel and KWin rewrite their files from memory during a session. Runner up: live reload over D-Bus, which only some files support.
- **System file mode**: root:root, 755 when executable in the repo, else 644; `/etc/sudoers.d` excluded, since a bad file there locks you out of sudo. Runner up: per file modes in a manifest, not needed for the files in scope.
- **Hook wiring**: `core.hooksPath hooks`, set by `dot install`. Runner up: copying into `.git/hooks`, which is not versioned.
- **Deny list format**: extended regex per line for `grep -E -f`. Runner up: gitleaks rules, a heavier tool you did not pick.

## References

**Project sources**:
- `AGENTS.md` (current layout, symlink rule, nvim submodule flow, public repo rule, `git add .` gotcha)
- `docs/scope/scope.md` (decisions of 2026-10-11: coverage, public repo, two profiles, system files)
- Local checks on 2026-10-11: `kwriteconfig6` writes through a symlink and keeps it; tmux `#{q:...}` keeps a path with a quote as one argument

**Practices & standards**:
- GNU Stow manual: packages, `--no-folding`, `--adopt`, `-n` dry run (cited by name; the page did not load during the check)
- KDE Plasma look and feel (Global Theme) package docs: what a theme can set, and that shortcuts and window rules are outside it (cited by name; not verified on the web, based on knowledge)
- Strangler pattern for migrating a live setup piece by piece

**Links** (web verified 2026-10-11):
- Arch package `stow` (extra): https://archlinux.org/packages/extra/x86_64/stow/
- git hooks (`pre-commit`, non zero exit aborts, `core.hooksPath`, `--no-verify` bypass): https://git-scm.com/docs/githooks
- MacTahoe KDE theme (LGPL-3.0): https://github.com/vinceliuice/MacTahoe-kde
- MacTahoe icon theme: https://github.com/vinceliuice/MacTahoe-icon-theme
