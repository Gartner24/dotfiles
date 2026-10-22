# 0011. claude-config as a submodule: move the working clone in, keep the old path as a link

**Date**: 2026-10-14
**Status**: Proposed
**Paths:** `dot`, `.gitmodules`, `claude-config`, `profiles/server`, `tests/dot-status.sh`, `tests/server-profile.sh`, `docs/specs/0001-repo-layout-linking/index.md`
**Builds**: [0001](../0001-repo-layout-linking/index.md) AC-16 and its migration phase 5. Feature 1, its last open box.

## Summary

Spec 0001 AC-16 decided that `~/claude-config` (`Gartner24/claude-config`, your Claude Code setup) becomes a submodule at `dotfiles/claude-config/`, on both profiles, installed by its own `install.sh` and synced by its own `sync.sh`, which `dot install` and `dot sync` call. It waited for the runner branch to merge. That merge is done (personal scope row 13), but on 2026-10-14 claude-config is on another unmerged branch, `feat/release-4`, and the `wf` runner (the overnight build tool, which lives in claude-config) points at `~/claude-config` in three `~/.local/bin` links (`wf`, `next`, `spec-paths`) and in its trust list `~/.config/wf/allowed.json`. This spec decides how to move without breaking any of that: move the working clone itself (no second copy), leave `~/claude-config` as a symlink to the new place, and re-run claude-config's installer and `wf allow` once.

## What you're agreeing to

- Your `~/claude-config` folder moves to `~/dotfiles/claude-config` and becomes the submodule; `~/claude-config` stays as a link to it, so your habits, notes and links keep working.
- The move happens only when claude-config is on `main`, clean, pushed, and no `wf run` is active; you start it.
- After the move you run `wf allow ~/dotfiles/claude-config` once (the runner compares real paths), and claude-config's own `install.sh` relinks `wf`, `next` and `spec-paths`.
- `dot install` runs claude-config's installer and `dot sync` runs its `sync.sh` first, on desktop and server.
- `~/.config/wf/` is never tracked by dotfiles or claude-config.

Context, options and rationale: [rationale.md](rationale.md).

## Requirements

**User stories**:
- As the owner, I want claude-config to come with my dotfiles on every machine, as a child repo like nvim.
- As the owner, I want the move not to break the runner, my sessions or my notes.

**Acceptance criteria**:
- **AC-1** (preconditions): the move step refuses, printing which one failed, unless: claude-config's branch is `main`, `git status --porcelain` is empty, `main` equals `origin/main`, no process runs `wf.py` (`pgrep -f runner/wf.py` empty), and `~/dotfiles/claude-config` does not exist.
- **AC-2** (move): `mv ~/claude-config ~/dotfiles/claude-config`, then `git -C ~/dotfiles submodule add git@github.com:Gartner24/claude-config.git claude-config` (git adopts the existing clone in place; its `.git` folder stays where it is, no `absorbgitdirs`), then `ln -s dotfiles/claude-config ~/claude-config`. `.gitmodules` gains the entry; `claude-config` is listed in `profiles/server`.
- **AC-3** (install): `dot install` initializes the submodule when missing and runs `claude-config/install.sh` (with `--dry-run` under `-n`) after linking packages. A non zero exit prints `claude-config: install.sh failed (exit <n>)` and makes `dot install` exit 1 after finishing its other steps.
- **AC-4** (sync): `dot sync` runs `claude-config/sync.sh` before staging, then treats the pointer like any submodule (0001 AC-10: clean and pushed, or refused).
- **AC-5** (runner and links): after the move, `readlink -f ~/.local/bin/wf` resolves inside `~/dotfiles/claude-config/` or to the runner copy claude-config's installer makes (its spec 0020 AC-12), `wf queue` runs, and `~/.config/wf/allowed.json` holds the new real path after `wf allow`. Nothing under `~/.config/wf/` is tracked: `deny.list` gains the path pattern `^([^ ="']*/)?\.config/wf/`, anchored like its other file patterns, so a new file there is refused while a line that mentions the folder is not.
- **AC-6** (server test): `tests/server-profile.sh` runs `dot install server -n` with the submodule present and checks that the claude-config dry run line is printed (closes 0003 Follow-up). Installing node, python3 and jq for its self checks is claude-config's own business (0001 AC-16).
- **AC-7** (tests): `tests/dot-status.sh` covers AC-3 and AC-4 with a stand-in submodule whose `install.sh` and `sync.sh` log their arguments: install passes `--dry-run` under `-n`, a failing `install.sh` gives exit 1, sync calls `sync.sh` before `git add`.

## Feature design

**Value sourcing**:

| Action | Value | Source |
|---|---|---|
| move | remote URL | `git -C ~/claude-config remote get-url origin` (`git@github.com:Gartner24/claude-config.git`, read 2026-10-14) |
| move | preconditions | AC-1 |
| install | installer and flag | `claude-config/install.sh`, `--dry-run` (its own usage line) |
| sync | sync script | `claude-config/sync.sh` |
| runner | trusted path | `~/.config/wf/allowed.json`, written only by `wf allow` (you) |

**Key invariants**:
- One clone of claude-config on this machine, reachable by both paths.
- `~/.config/wf/` never enters any repo.
- A claude-config pointer is committed only when that commit is on its remote (0001 AC-10).

**Security model**: both repos are public; claude-config's own commit hooks keep work names out (its spec 0013). Moving the folder changes no file content. `deny.list` blocks new files under `.config/wf/` (the runner's topic, codes and block list).

**Critical test scenarios**:
- Stand-in submodule cases in `tests/dot-status.sh`. Verifies **AC-3**, **AC-4**, **AC-7**.
- The move on this machine, then `wf queue`, `claude --version` from `~/claude-config`, `dot status`. Verifies **AC-2**, **AC-5**.
- Server container dry run. Verifies **AC-6**.

## Build plan

1. `dot install` and `dot sync` call the submodule's scripts when `claude-config/` exists; tests with a stand-in. Satisfies **AC-3**, **AC-4**, **AC-7**.
2. `deny.list` path pattern for `.config/wf/`. Satisfies **AC-5** (part).
3. A `tests/claude-config-move.sh` that checks AC-1 and prints the AC-2 commands (`-n` default, `--run` to execute). Satisfies **AC-1**.
4. You run the move when the preconditions hold, then `claude-config/install.sh`, `wf allow ~/dotfiles/claude-config`, `wf queue`. Waits on you. Satisfies **AC-2**, **AC-5**.
5. Commit `.gitmodules`, the pointer and `profiles/server`; server container dry run. Satisfies **AC-2**, **AC-6**.
6. Tick 0001's AC-16 milestone in the scope.

## Probes

| Probe | Command | Result |
|---|---|---|
| P1 what points at the old path | `find ~/.local/bin -maxdepth 1 -type l -lname '*claude-config*'`; `grep -rl claude-config ~/.config/wf ~/.config/systemd/user ~/.claude/settings.json` | ran 2026-10-14: `wf`, `next`, `spec-paths`; `~/.config/wf/allowed.json` |
| P2 runner compares real paths | `grep -n realpath ~/claude-config/runner/wf.py` | ran 2026-10-14: yes, so the trust list needs the new real path |
| P3 branch state | `git -C ~/claude-config status -sb` | ran 2026-10-14: `feat/release-4`, so the move waits |
| P4 `submodule add` adopts an existing clone | in a scratch folder: `git init a; git clone <a> b/sub; git -C b init; git -C b submodule add <url> sub` | prints "Adding existing repo"; build runs it in the scratchpad before step 4 |
| P5 Claude Code session history after the move | start `claude` in `~/claude-config` (the link) and check the project folder under `~/.claude/projects/` | you, after the move; if it starts a new history folder, old sessions stay readable under the old name |

## Consequences

**Positive**:
- A new machine gets the Claude setup with the dotfiles; one clone, two paths.

**Negative / tradeoffs**:
- Every claude-config change now also needs a pointer commit in dotfiles (third submodule).
- The move is a manual, timed step.

**Neutral**:
- Spec 0001's Deferred claude-config reorganization stays deferred.

## Follow-up

- [ ] Update `~/.claude/CLAUDE.md` and memory notes only if P5 shows the link path is not enough.
