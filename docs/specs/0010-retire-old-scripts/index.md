# 0010. Retire the old scripts: delete `install.sh` and `sync-to-github.sh` once `dot` covers them

**Date**: 2026-10-14
**Status**: Proposed
**Paths:** `install.sh`, `sync-to-github.sh`, `AGENTS.md`, `README.md`, `profiles/server`, `home/zsh/.zshrc`, `home/zsh-desktop/**`, `tests/readme.sh`
**Builds on**: [0001](../0001-repo-layout-linking/index.md) migration plan (strangler: old scripts deleted last), [0008](../0008-package-list-bootstrap/index.md), [0009](../0009-readme-architecture/index.md) AC-4. Feature 12.

## Summary

`install.sh` (dependencies, NVM, mise, Oh My Zsh, the dock links, the pacman hook, `chsh`) and `sync-to-github.sh` (`git add .` then push, the one that can publish anything untracked) were kept working while programs moved into the new layout. After features 8 and 10 every job they did has a `dot` command. This spec checks that, job by job, deletes both files, and makes sure nothing in the live repo still points at them. Historical specs and the scope keep their mentions; they record what happened.

## What you're agreeing to

- `install.sh` and `sync-to-github.sh` are deleted, after a table shows each of their jobs and the `dot` command that does it now.
- NVM is no longer installed anywhere (your shell uses mise since March).
- Nothing outside `docs/` mentions the two scripts, NVM or WSL, checked by a test.
- Old specs and the scope are left as they are; they describe the past.

Context, options and rationale: [rationale.md](rationale.md).

## Requirements

**User stories**:
- As the owner, I want one way to install and sync, so I never run the script that pushes everything.

**Acceptance criteria**:
- **AC-1** (coverage table): before deletion, every job in *Jobs* below has its replacement present and tested (the named spec's AC passes in its test file). A job with no replacement stops the build and is a question for you.
- **AC-2** (delete): `install.sh` and `sync-to-github.sh` are removed with `git rm` in one commit.
- **AC-3** (no pointers): `tests/readme.sh` stale word check (0009 AC-4) is switched on and extended to every tracked file outside `docs/`: no `install.sh` (except inside the `kde-theme` and `claude-config` submodules, whose own installers keep that name), `sync-to-github`, `nvm`, `NVM_DIR`, `WSL`. `p10k` stays allowed: the starship and zsh comments explain settings by what p10k did. It prints each `file:line` and the count; 0 required.
- **AC-4** (comments): the `profiles/server` comment on zsh and any shell comment that says Oh My Zsh comes from `install.sh` now names `dot bootstrap`.
- **AC-5** (this machine): `~/.local/share/plasma/plasmoids/org.santiago.macdock` and `~/.local/bin/real-app-icons` point into `kde-theme/` (spec 0006), not at the deleted root paths; `dot status` reports no broken link.

## Feature design

**Jobs** (from reading both scripts, 2026-10-14):

| Old job | Old place | Replacement |
|---|---|---|
| install base packages (Arch, apt) | `install.sh` `install_dependencies` | `dot bootstrap` (0008 AC-4, AC-5) |
| GUI packages, Hack Nerd font | `install.sh` | `packages/desktop` (`ttf-hack-nerd`, `alacritty`, `ghostty`) |
| eza from GitHub on Ubuntu | `install.sh` | `server-apt.tsv` mise fallback (0008 AC-5) |
| docker group | `install.sh` | 0008 AC-6 |
| NVM and node LTS | `install.sh` | dropped: node comes from mise (`home/mise`, 0002) |
| mise | `install.sh` | `packages/server` (pacman) and `repo:mise` (0008) |
| clone dotfiles, submodules | `install.sh` | README install steps (0009 AC-1), `dot install` submodule init (0001 AC-13) |
| Oh My Zsh and plugins | `install.sh` | 0008 AC-6 |
| dock and `real-app-icons` links | `install.sh` | `kde-theme/install.sh --link` (0006 AC-3) |
| pacman hook | `install.sh` | `system/real-app-icons` (0006 AC-6) |
| `chsh` to zsh | `install.sh` | 0008 AC-6 |
| `--sync` mode (pull, relink) | `install.sh` | `git pull` then `dot install` (README *Daily use*) |
| commit and push everything | `sync-to-github.sh` | `dot sync` (scoped staging, asks before push, 0001 AC-10) |

**Value sourcing**:

| Action | Value | Source |
|---|---|---|
| AC-1 | the jobs | the two scripts as of 2026-10-14 (table above) |
| AC-3 | stale words | the list in AC-3 |
| AC-3 | files checked | `git ls-files` minus `docs/` and submodule contents |

**Key invariants**:
- After this feature the only entry points are `dot` and the submodules' own installers.

**Security model**: removing `sync-to-github.sh` removes the one path that ran `git add .` on a public repo.

**Critical test scenarios**:
- Add a line mentioning `install.sh` to `README.md`: the check prints it, count 1 (mutation check). Verifies **AC-3**.
- `dot status` on this desktop after the delete: no broken link. Verifies **AC-5**.

## Build plan

1. Walk *Jobs*; for each row run the replacement's test. Stop on a gap. Satisfies **AC-1**.
2. Update the comments. Satisfies **AC-4**.
3. `git rm` both scripts. Satisfies **AC-2**.
4. Turn on and extend the stale word check; fix every hit outside `docs/`. Satisfies **AC-3**.
5. `dot install desktop`, `dot status`. Satisfies **AC-5**.

## Probes

None: only repo files and `dot status` on this machine.

## Consequences

**Positive**:
- No script left that pushes untracked files.

**Negative / tradeoffs**:
- A machine set up with the old script and never re-bootstrapped keeps NVM; harmless, removed by hand if wanted.

**Neutral**:
- Old specs still mention the scripts as history.

## Follow-up

- [ ] After this, the scope has no open feature except whatever spec 0011 (claude-config submodule) still needs.
