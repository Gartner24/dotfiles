# 0001. Stow packages per program, copied KDE and system files, one deny list

**Date**: 2026-10-11
**Status**: In Progress

## Summary

Each program you configure gets its own folder under `home/`, and GNU Stow (a small tool that creates symlinks, links that point back to the repo) links those folders into your home folder, so editing a config edits the repo directly. Files that must not be linked are copied instead: system files under `/etc` (copied with sudo after showing a diff) and the KDE settings files KDE keeps rewriting (copied through a filter so recent files and device names never reach the public repo). Your custom KDE look becomes its own public theme repo, pulled in as a submodule (a repo inside a repo), like nvim. One `./dot` script installs, syncs and reports status, and one deny list plus a commit check (a test git runs before every commit, the `pre-commit` hook) keeps personal state out of every commit.

## Requirements

**User stories**:
- As the owner, I want every program I configure in its own folder so I can see, add or drop a program as one unit.
- As the owner, I want to set up a desktop or a server from one command that installs only that profile's programs.
- As the owner, I want edits to flow back with one command that never publishes personal state or files I did not mean to add.

**Acceptance criteria**:
- **AC-1**: The repo root holds `home/`, `system/`, `kde/`, `kde-theme/`, `claude-config/`, `profiles/`, `hooks/`, `docs/`, `dot`, `deny.list`, the agent context files and `README.md`. No program config sits at the root once its slice has moved it.
- **AC-2**: Every folder under `home/<pkg>/` mirrors paths relative to `~` and is linked with `stow --no-folding -d home -t ~ <pkg>`. Only files are linked, never whole directories, so a program writing new state files into its config folder writes them into `~`, not into the repo.
- **AC-3**: `profiles/server` and `profiles/desktop` list package names, one per line, `#` for comments. Installing the desktop profile installs every server package plus the desktop list. A package name appears in at most one list; `dot status` reports a duplicate or a name with no folder.
- **AC-4**: `dot install <desktop|server>` saves the profile to `.dot-profile` (gitignored) and links that profile's packages. Later `dot install`, `dot sync` and `dot status` read the saved profile when no argument is given, and stop with a message when there is none. `dot` finds the repo from its own resolved path (`readlink -f "$0"`), not the current folder. It checks only the tools its profile needs (`stow` and `git` always, `kwriteconfig6` and `kreadconfig6` on desktop only). Exit codes: 0 ok, 1 failure, 2 bad usage (no arguments or `-h` prints usage).
- **AC-5**: `dot install -n` (dry run) prints every link it would create, every file it would back up and every system diff, and changes nothing.
- **AC-6**: When a real file sits where a link should go, install moves it to `~/.dotfiles-backup/<YYYY-MM-DD-HHMMSS>/<same relative path>` and then links. Nothing is overwritten, and no repo file is changed by install. A link that points into this repo but outside `home/` (the old root layout) is replaced without a backup entry. The backup folder is created only when something is moved; two runs in the same second get a `-N` suffix.
- **AC-7**: Files under `system/<name>/` mirror absolute paths (`system/keyd/etc/keyd/default.conf`). A system folder belongs to the profile whose list names it. Install shows a diff against the live file (against `/dev/null` when absent) and, per file, copies with `sudo install -D -o root -g root` (mode 755 when the repo file is executable, else 644) only after you answer y; with `-n` or no terminal it never prompts and never writes. They are never symlinked. `/etc/sudoers.d` is excluded. `dot` never restarts services; it prints which ones may need it. `dot sync` shows drift (live file differs from repo) and asks before copying a live file back; a live file matching `deny.list` is refused and reported.
- **AC-8**: KDE rc files that KDE rewrites are never linked. `kde/allow.list` names each kept key as `<rcfile> <Group> <Key>` per line (nested groups as `Group/Sub`, `#` comments, blank lines ignored). `dot sync` reads exactly those keys with `kreadconfig6` into `kde/<rcfile>`; a key not listed can never reach the repo. Install writes them back with `kwriteconfig6`, one key per call, merging into the live file (keys removed from the repo are not removed on the target, accepted), then tells you to log out and back in, because the running session can rewrite those files from memory.
- **AC-9**: `deny.list` holds one extended regex per line; `#` comments and blank lines are stripped before use. `hooks/pre-commit` (executable in git) scans only lines added by the commit (`git diff --cached -U0`), skips binary files, deletions and submodule pointers, exempts `deny.list` itself, and refuses the commit when a line matches, printing the count and each `file:line`. It also refuses when `deny.list` is missing or empty after stripping. `dot install` sets `git config core.hooksPath hooks`, so the check also runs on manual commits.
- **AC-10**: `dot sync` stages tracked changes (including deletions) with `git add -u -- home system kde profiles`, lists new untracked files there (`git ls-files -o --exclude-standard`) and asks before adding them, never runs `git add .`. It refuses to stage a submodule pointer (nvim, kde-theme, claude-config) unless that submodule is clean and its commit is on its remote, and says so. Changes elsewhere (`dot`, `hooks/`, `docs/`, `README.md`, `deny.list`) are listed as outside sync scope for a manual commit. It commits with `sync: <first 5 paths> (+N more)`, shows the commit, and asks y/N before pushing; a rejected push prints the error and exits 1, with no automatic pull.
- **AC-11**: nvim lives as a submodule at `home/nvim/.config/nvim` and is linked like any package. Its own repo (`Gartner24/nvim.lua`) and its commit first, pointer second flow stay unchanged.
- **AC-12**: Personal scripts live in two packages, `home/bin/.local/bin/` (both profiles) and `home/bin-desktop/.local/bin/` (desktop only). Installed tools in `~/.local/bin` (uv, yt-dlp) are untouched.
- **AC-13**: The custom KDE look (Global Theme, Mac Dock plasmoid, real-app-icons and anything else built for it) moves to its own public repo, added as a submodule at `kde-theme/`, with a credits file naming every upstream project it builds on and a license compatible with them. Its own installer supports a link mode (so dock edits stay live) and a mode that skips the panel layout. `dot install desktop` calls it in link mode without the layout unless you pass `--apply-layout`. Install initializes only the submodules its profile uses (`git submodule update --init <path>`); the server profile never pulls `kde-theme`.
- **AC-16**: `~/claude-config` (`Gartner24/claude-config`) is a submodule at `claude-config/`, on both profiles, never a stow package: its repo copy differs from `~/.claude` on purpose (`autoMode` stripped, home path rewritten to `$HOME`). `dot install` runs its `install.sh` (passing `--dry-run` under `-n`); `dot sync` runs its `sync.sh` first, then treats its pointer like any submodule (clean and pushed, or refused). Its frameworks and plugins stay its own installer's business.
- **AC-14**: Install links with `stow -R --no-folding` so a rerun also removes links to files deleted from a package. `dot status` prints one line per package (`linked`, `partial`, `not linked`), lists repo files with no link, broken links, links into the repo that no listed package owns (from a dropped package), the same file in two packages, and duplicate or unknown profile names; it exits non zero when it finds any. Packages dropped from a profile are reported, never unlinked automatically (`stow -D` by hand).
- **AC-15**: Before the new layout is declared clean, the existing git history is scanned once against `deny.list` (`git log -p --all`), and any hit is reported for you to decide on.

## Decision

**Chosen option**: Option 1: GNU Stow packages, plus copy paths for system and KDE files.

Programs are stow packages under `home/`, system files and rewritten KDE files are copied (with a diff or a filter), the KDE look is a separate published submodule, profiles are plain lists, and one deny list is enforced by both `dot sync` and a pre-commit hook.

## Rationale

Reasoning and options: see [rationale.md](rationale.md).

## Feature design

**Repo layout (target)**:
```
dot                      # bash entry point: install | sync | status
deny.list                # regex per line, personal state that must never be committed
profiles/server          # lean set
profiles/desktop         # extras only; server is included automatically
home/<pkg>/...           # stow packages, paths relative to ~
  home/zsh/.zshrc
  home/tmux/.tmux.conf
  home/ghostty/.config/ghostty/config
  home/nvim/.config/nvim/        # submodule
  home/bin/.local/bin/...
  home/bin-desktop/.local/bin/tmux-zen
system/<name>/etc/...    # copied with sudo after a diff
kde/allow.list           # <rcfile> <Group> <Key> per line
kde/<rcfile>             # only the allowed keys (shortcuts, window rules, input, power)
kde-theme/               # submodule: published Global Theme, dock, icons, own installer
claude-config/           # submodule: Claude Code config, own install.sh and sync.sh
hooks/pre-commit         # deny list check
docs/                    # specs and scope, never linked
.dot-profile             # gitignored, saved profile of this machine
```

**Commands (the interface)**:
| Command | Inputs | Does | Fails when |
|---|---|---|---|
| `dot install [desktop\|server] [-n] [--apply-layout]` | profile (saved after first run), dry run flag | checks profile tools, sets hooksPath, inits profile submodules, backs up conflicts, restows profile packages, diffs and copies system files, writes KDE keys and asks you to log out (desktop), runs the theme installer (desktop) | no profile given or saved (exit 2); a needed tool missing; a profile names a folder that does not exist; stow refuses (parent in `~` is a foreign link) |
| `dot sync` | none | reads allowed KDE keys, shows system drift, stages tracked changes, checks submodules, lists new and out of scope files, commits, asks before push | deny pattern found (hook); push rejected (exit 1); nothing to commit (exits 0 with a message) |
| `dot status` | none | per package state, unlinked repo files, broken and orphan links, file in two packages, duplicate or unknown profile names, system drift, KDE keys that differ from repo | read only; exits non zero when it finds a problem |

**Value sourcing**:
| Action | Value | Source |
|---|---|---|
| install | which packages | `profiles/server`, plus `profiles/desktop` for the desktop profile |
| install, sync, status | which profile this machine is | argument to `dot install`, saved in `.dot-profile` |
| install | backup folder name | timestamp at run start, `date +%F-%H%M%S`, plus `-N` on collision |
| install | system file mode and owner | root:root; 755 if the repo file is executable, else 644 |
| install | which system folders and submodules | the same profile lists as packages |
| install | link target | `~` (fixed), stow `-t ~` |
| install | system file destination | the path under `system/<name>/` with that prefix removed |
| sync, install | which KDE keys are kept | `kde/allow.list` |
| sync, hook | what counts as personal state | `deny.list` |
| sync | commit message | `sync: <first 5 changed paths> (+N more)` |
| sync | whether a submodule pointer may be staged | submodule clean and `git -C <sub> branch -r --contains HEAD` not empty |
| install (desktop) | whether panels are reset | `--apply-layout` flag, default off |

**Key invariants**:
- Stow always runs with `--no-folding`; no directory under `~` is ever a link into the repo.
- Nothing under `/etc` is a link into `~`.
- No KDE rc file KDE rewrites is linked.
- No commit contains a line matching `deny.list` while the hook is active.
- Install never modifies a tracked repo file (no `--adopt`).
- `~/.local/bin` stays a real folder; `--no-folding` is required so installed tools there (uv, yt-dlp) are untouched.
- Stow skips some names by default (`README*`, `LICENSE*`, `.gitignore`, `.git`); such files inside a package are not linked. This is what keeps a submodule's `.git` out of `~`, and is accepted for the rest.
- No commit stages a submodule pointer to a commit missing from that submodule's remote.
- Every program is in exactly one package; every package is in at most one profile list.

**Security model**: the repo is public. `deny.list` starts with history file names, `.git-credentials`, `~/.config/claude-fb/keys.env`, token prefixes (`ghp_`, `gho_`, `github_pat_`, `AKIA`, `xox[bp]-`, `sk-ant-`), private key headers (`-----BEGIN .*PRIVATE KEY-----`), and wifi or wireguard secret keys (a `psk` or `PrivateKey` assignment). System files are written only with `sudo install` after you see the diff, and copied back only after a deny scan. KDE is safe by construction: only named keys are ever read. The hook is the last line of defense; it can be skipped with `--no-verify` and is absent on a clone until `dot install` runs, both accepted.

**Configuration required**: none (no env vars). New tool: GNU Stow, from the distro package manager on every profile.

**Critical test scenarios**:
- Happy path: `dot install desktop -n` on this machine lists the expected links and backups and changes nothing; then a real install leaves `~/.zshrc` linked to `home/zsh/.zshrc` and a new shell starts. Verifies **AC-2**, **AC-4**, **AC-5**.
- Conflict: a real `~/.config/alacritty/alacritty.toml` exists; install moves it to the backup folder with its path and links the repo copy. Verifies **AC-6**.
- Deny: stage a file adding a line that matches `deny.list`; `git commit` is refused with the `file:line`. Remove the pattern and the same commit goes through (mutation check). A commit editing `deny.list` itself passes; an empty `deny.list` blocks. Verifies **AC-9**.
- KDE: with a recent file entry and a device name in the same group as an allowed key, run `dot sync`; the repo copy holds only the allowed key. Verifies **AC-8**.
- Sync: create an untracked file in `home/zsh/`; `dot sync` lists it and does not stage it unless you answer y; push waits for y. Make an unpushed commit in the nvim submodule; sync refuses its pointer. Verifies **AC-10**.
- Rerun: delete a file from a package and rerun install; its link is gone and `dot status` exits 0. Remove a package from its profile; status reports its orphan links and exits non zero. Verifies **AC-14**.
- System: `dot install -n` with a changed `system/keyd` file prints the diff and writes nothing; the real run writes it root owned, 644. Verifies **AC-7**.
- Profiles: `dot install server -n` lists only server packages, and no `bin-desktop`, ghostty or KDE item. Verifies **AC-3**, **AC-12**.

## Build plan

Tracer Bullet: build the mechanics first and prove them end to end on the files already here, without moving any program yet. Feature 3 (zsh) is the first program pushed through them.

1. Install `stow`; add `.dot-profile` and `.dotfiles-backup` handling to `.gitignore`. Satisfies **AC-2**, **AC-4**.
2. Create `deny.list` with the starting patterns and `hooks/pre-commit` (added lines only, binaries skipped, `deny.list` exempt, fails on a missing or empty list); verify with a staged match and a mutation check. Satisfies **AC-9**.
3. Create `profiles/server` and `profiles/desktop` (empty but for comments) and the profile reader (desktop includes server, duplicate and unknown name check). Satisfies **AC-3**.
4. Write `dot install` for stow packages: own path resolution, usage and exit codes, profile argument and save, tool check per profile, dry run, backup then `stow -R --no-folding`, old layout links replaced, hooksPath setup, profile submodule init. Satisfies **AC-2**, **AC-4**, **AC-5**, **AC-6**, **AC-13**, **AC-14**.
5. Write `dot status` (per package state, unlinked files, broken and orphan links, file in two packages, unknown and duplicate names, non zero exit on problems). Satisfies **AC-3**, **AC-14**.
6. Write `dot sync` for tracked files: `git add -u` on the four folders, untracked and out of scope listing, submodule pointer guard, bounded commit message, ask before push. Satisfies **AC-10**.
7. Add the system copy path (diff, per file prompt, `sudo install` with owner and mode, sudoers.d excluded, drift and deny scan in sync, drift in status, service hint) with one real file (`/etc/keyd`) as the thread. Satisfies **AC-7**.
8. Add the KDE copy path (`kde/allow.list` per key, `kreadconfig6` in, `kwriteconfig6` out, log out notice) with one file (`kglobalshortcutsrc`) as the thread. Satisfies **AC-8**.
9. Document the layout in the README section feature 11 later expands, and update `AGENTS.md` Rules (files now mirror under `home/<pkg>/`, not the root). Satisfies **AC-1**.
10. Scan the existing git history once against `deny.list` and report hits. Satisfies **AC-15**.

Later features move programs into the layout (3 zsh, 4 terminals and nvim with **AC-11**, 5 scripts with **AC-12**, 8 theme submodule with **AC-13**).

## Migration plan

**Strategy**: strangler. The old root files and old `install.sh` and `sync-to-github.sh` keep working while each program moves in its own slice; feature 12 deletes the old scripts.
**Phases**:
1. Mechanics (this spec's build plan), no program moved.
2. Per program slice: `git mv` the file into `home/<pkg>/`, remove the old link in `~`, `dot install`, check the program, commit. The old scripts are edited to drop that program in the same commit, so the two never link the same file.
3. nvim: push the 1 local commit and commit or drop the 2 modified files in `~/.config/nvim` first, then `git mv .config/nvim home/nvim/.config/nvim`, move the standalone clone to the backup folder, and stow the package.
4. KDE theme: create the theme repo, move the dock, real-app-icons and its hook there, add it as `kde-theme/`, publish it.
5. claude-config: once `feat/seo-ops-refs` is merged and synced (personal scope item 2), `git submodule add` it at `claude-config/`, move the standalone `~/claude-config` clone aside, and point its users (`~/.claude/CLAUDE.md`, memory notes) at the new path.
**Rollback**: per slice, `stow -D -d home -t ~ <pkg>`, `git revert` the slice commit, and relink the old path; backups in `~/.dotfiles-backup/` restore anything install moved.
**Risks**: a program missed in the old scripts gets linked twice (caught by `dot status` broken link check); the standalone nvim clone holds unpushed work (phase 3 pushes first); applying the theme layout on this machine resets your panels (off by default).

## Consequences

**Positive**:
- One mental model: a program is a folder, a profile is a list, a sync is a scoped commit.
- Edits to linked files are already in the repo; only KDE and system files need a copy step.
- KDE keys reach the repo only when named, so a missed deny pattern cannot leak KDE state; everything else is checked at commit time, including manual commits.

**Negative / tradeoffs**:
- Stow becomes a dependency on every machine, including servers.
- KDE and system files are copies, so they can drift; you see the drift only when you run `dot sync` or `dot status`.
- Three submodules (nvim, kde-theme, claude-config) means three commit first, pointer second flows.
- The hook only runs where `dot install` set `core.hooksPath`; a fresh clone without install has no check until then.
- `--no-folding` creates many links instead of a few directory links, and a file added to a package is linked only on the next `dot install`.
- A KDE restore needs a log out to stick, and keys removed from the repo stay on the target machine.
- `kde/allow.list` is long: every kept key is listed by name.

**Neutral**:
- `kde/real-app-icons.hook` and `.local/share/plasma/` leave this repo for the theme repo.
- `AGENTS.md` Rules and Gotchas change (layout, sync no longer runs `git add .`).

## Follow-up

- [ ] Feature 7 (KDE settings) decides the exact rc files and keys in `kde/allow.list`.
- [ ] Feature 7 or 8 names the theme repo and checks the license of each upstream project it builds on before publishing (MacTahoe-kde is LGPL-3.0; the icon theme, WhiteSur cursors, AndromedaLauncher and KdeControlStation are not checked yet).
- [ ] Feature 13 confirms stow is packaged on the chosen server distros, and that claude-config's `install.sh` runs headless (its self checks need `node`, `python3` and `jq`).
- [ ] claude-config's own reorganization stays the deferred scope item; this spec only fixes where it sits and how `dot` calls it.
- [x] `fixall` in `.zshrc` numbers its steps 1/5 to 4/5 then 5/6 and 6/6; worth fixing when zsh moves (feature 3).
