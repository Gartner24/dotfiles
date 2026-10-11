# Verify: repo layout and linking method · spec 0001 · updated 2026-10-11
_Steps come from the spec 0001 acceptance criteria. `/check verify` runs them and `/test` locks the ones worth keeping. Already passed in a sandbox (fake HOME, copied repo) during /develop unless marked "tty", which needs a real terminal._

## Commands
- [x] `./dot`, then `./dot install bogus`: usage printed, exit 2. `./dot -h`: usage, exit 0. -> AC-4
- [x] From another folder (`cd /tmp && ~/dotfiles/dot status`): works, because the repo is found from the script's own path. -> AC-4
- [x] Remove `.dot-profile`, run `./dot status`: message, exit 2. -> AC-4
- [x] Add a test package `home/t/.config/t/a`, list `t` in `profiles/desktop`, put a real file at `~/.config/t/a`. `./dot install -n`: prints the backup and the link, changes nothing, saves no profile. -> AC-5, AC-6
- [x] Same setup, `./dot install`: the real file sits in `~/.dotfiles-backup/<timestamp>/.config/t/a`, `~/.config/t/a` links to the repo, `~/.config/t` is a real folder, not a link. -> AC-2, AC-6
- [x] Delete `home/t/.config/t/a` (add a second file first), rerun install: its link is gone, `./dot status` exits 0. -> AC-14
- [x] Remove `t` from the profile: status reports an orphan link and exits 1; the link is still there. -> AC-14
- [x] List `t` in both profiles, and a name with no folder: status reports both; install refuses the unknown name. -> AC-3
- [x] `./dot install server -n` lists only server packages, no `keyd` diff, no KDE keys. -> AC-3
- [x] `git config core.hooksPath` prints `hooks` after an install. -> AC-9
- [x] Stage a line with a 36 char `ghp_` token: commit refused with `file:line`. Remove the `ghp_` pattern from `deny.list` and the same commit passes (mutation check). Editing `deny.list` alone passes; a comment only `deny.list` blocks every commit. -> AC-9
- [x] Stage a new file named `.zsh_history` anywhere: refused as `(path)`. A line `HISTFILE=~/.zsh_history` passes. -> AC-9
- [x] Stage a line starting `wifi ` followed by a psk assignment, and a line starting `[Interface] ` followed by a PrivateKey assignment (the secret mid line, not at its start): both refused. `mypsk` and `PrivateKeyFile` assignments pass. Put the old anchored psk pattern (start of line only) back and the wifi line passes (mutation check). -> AC-9
- [x] Stage a psk assignment in a file named `with space.txt`: refused as `with space.txt:1`, no tab before the colon. -> AC-9
- [x] List the same package in both profiles: `./dot install -n` exits 1 with "listed more than once in profiles". -> AC-3
- [x] Make `kwriteconfig6` fail during `./dot sync`: exit 1 and `kde/kglobalshortcutsrc` is unchanged, not deleted. A normal run reproduces the tracked file. -> AC-8
- [x] Edit a tracked file under `home/`, create an untracked one, edit `README.md`: `./dot sync` commits only the tracked edit, lists the new file (asks, tty), lists `README.md` as outside scope. -> AC-10
- [x] A submodule under `home/` with an unpushed commit: sync refuses its pointer; after pushing, sync takes it. -> AC-10
- [x] Seven changed files: commit message is `sync: <5 paths> (+2 more)`. -> AC-10
- [x] (tty) After a sync commit, answer N to push: nothing pushed. Answer y with a rejected push: error shown, exit 1, no pull. -> AC-10
- [x] Append a comment to `system/keyd/etc/keyd/default.conf`: `./dot install -n` shows the diff, writes nothing; `./dot status` reports drift. -> AC-7
- [x] (tty) Real install, answer y: `/etc/keyd/default.conf` is root:root 644, and the restart hint for keyd is printed. Answer N: nothing written. -> AC-7
- [x] (tty) Edit `/etc/keyd/default.conf` live, `./dot sync`: drift shown, asks before copying back. Put `psk=x` in it: refused as a deny.list match. -> AC-7
- [x] With a key in `[kwin]` of `~/.config/kglobalshortcutsrc` that is not in `kde/allow.list`, `./dot sync`: `kde/kglobalshortcutsrc` holds only the two listed keys. -> AC-8
- [x] Change `Window Maximize` live: status reports it, `./dot install` writes the repo value back and prints the log out notice. -> AC-8

## Value sourcing
- [x] Packages: a name added to `profiles/server` is linked on both profiles, one in `profiles/desktop` only on desktop. -> AC-3
- [x] Profile: `./dot install server` then `./dot status` uses server with no argument. -> AC-4
- [x] Backup folder: two installs in the same second give `<timestamp>` and `<timestamp>-1`. -> AC-6
- [x] System mode: an executable repo file installs as 755, others as 644, owner root. -> AC-7
- [x] System destination: `system/keyd/etc/keyd/default.conf` goes to `/etc/keyd/default.conf`; a file under `system/x/etc/sudoers.d/` is skipped. -> AC-7
- [x] KDE keys: only `kde/allow.list` decides what is read. -> AC-8
- [x] Personal state: only `deny.list` decides what is blocked. -> AC-9
- [x] Submodule pointer: allowed only when `git -C <sub> branch -r --contains HEAD` is not empty and the submodule is clean. -> AC-10

## Docs and history
- [x] README has the Layout section; AGENTS.md Rules describe `home/<pkg>/`. -> AC-1
- [x] History scan (run once 2026-10-11 over `git log -p --all`, added lines and added paths): 0 hits. The scanner was checked by scanning for `HISTFILE=`, which found its 2 known commits. -> AC-15

## Acceptance criteria coverage
- AC-1 docs step; AC-2, AC-4, AC-5, AC-6, AC-14 command steps; AC-3 profile steps; AC-7 system steps; AC-8 KDE steps; AC-9 hook steps; AC-10 sync steps; AC-15 history step.
- Not built here: AC-11, AC-12 (features 4, 5), AC-13 theme installer call and `--apply-layout` (feature 8; profile submodule init is built), AC-16 (claude-config milestone).

## Feature 3: zsh through the new layout · updated 2026-10-11
_Done during /develop on this machine unless marked "tty". The sync step ran in a sandbox (cloned repo, fake HOME)._
- [x] `.zshrc` and `.p10k.zsh` sit in `home/zsh/`, nothing zsh related is left at the repo root, `zsh` is in `profiles/server`. -> AC-1, AC-3
- [x] `./dot install -n`: prints a backup for the real `~/.p10k.zsh`, a link for it, "replace old link ~/.zshrc" and its link; changes nothing. -> AC-5, AC-6
- [x] `./dot install`: `~/.zshrc` and `~/.p10k.zsh` link into `home/zsh/`, the old `~/.p10k.zsh` is in `~/.dotfiles-backup/<timestamp>/`, `./dot status` prints `zsh: linked`. -> AC-2, AC-6, AC-14
- [x] `zsh -n home/zsh/.zshrc` passes; `zsh -i -c 'whence -w fixall up y'` finds the functions and p10k loads. -> AC-2
- [x] (tty) Open a new terminal: prompt, plugins, fastfetch and the shortcuts panel look as before. -> AC-2
- [x] Edit `~/.zshrc` through the link, `./dot sync`: commits `sync: home/zsh/.zshrc` and asks before push. -> AC-10
- [x] `install.sh` and `sync-to-github.sh` no longer link or copy `.zshrc`, so the two layouts never touch the same file. -> AC-1
- [x] README has a zsh section; AGENTS.md points at `home/zsh/.zshrc`. -> AC-1
- [x] `./dot install server` (sandbox) links `zsh`, so a server gets it too. -> AC-3
