# 0009. README and architecture docs: a README a stranger can install from, and a system view for later decisions

**Date**: 2026-10-14
**Status**: Proposed
**Paths:** `README.md`, `docs/architecture.md`, `AGENTS.md`, `tests/readme.sh`, `tests/server-profile.sh`
**Builds on**: specs 0001 to 0008. Feature 11.

## Summary

The README still opens with "Neovim, Zsh, Tmux, portable including WSL" and installs through `install.sh`; only its *Layout* section describes the new repo. This spec rewrites it around the four things you do (install a machine, sync changes back, check status, add a program) and describes every folder. It also adds `docs/architecture.md`: a one page system view (the parts, how they connect, and the rules that must stay true, each pointing at the spec that set it) that `/architect` reads before any later decision. Two checks keep both honest: every folder is named in the README, and the README's server install block is the exact script the container test runs.

## What you're agreeing to

- The README is rewritten: what is in the repo, install for desktop and server, sync, status, adding a program, the three submodules.
- A new `docs/architecture.md` lists the parts and the rules every later change must keep, with the spec each rule comes from.
- A test fails when a folder is missing from the README, or when the README's server install steps stop working in the six server containers.
- WSL and Ubuntu desktop are no longer mentioned; the desktop is Arch with KDE Plasma.

Context, options and rationale: [rationale.md](rationale.md).

## Requirements

**User stories**:
- As the owner on a new machine, I want to follow the README top to bottom and end with my setup.
- As a future `/architect` session, I want the repo's rules in one page so a decision does not break one silently.

**Acceptance criteria**:
- **AC-1** (README sections, in order): what this is (two profiles, public, what is never committed); *Install* (desktop and server, from a bare machine: install git, clone with submodules, `./dot bootstrap <profile>`, log out and in on desktop); *Daily use* (`dot status`, `dot sync`, `dot install` after a pull); *Add a program* (package folder, profile line, `packages/` line); *Layout* (one line per top level entry); *Programs* (one line per `home/` package and `system/` folder, with profile); *KDE* (allow list and `!` lines, apply tools, `kde-theme`, `--apply-layout`, the screenshot reference check); *Submodules* (nvim, kde-theme, claude-config: commit inside first, pointer second); *Tests* (each `tests/*.sh`, what it needs).
- **AC-2** (every folder named): `tests/readme.sh` walks `git ls-files` top level entries, `home/*`, `system/*`, `packages/*` and the submodule paths, and prints each one the README does not mention in backticks, then `<n> missing`; n must be 0.
- **AC-3** (install block runs): the README's server install commands sit between `<!-- server-install -->` and `<!-- /server-install -->`. `tests/server-profile.sh` extracts that block and runs it (as root, `sudo` stripped) instead of its own setup, in all six images, before its shell checks.
- **AC-4** (no stale claims): `tests/readme.sh` also fails on any of `install.sh`, `sync-to-github`, `WSL`, `nvm` in `README.md` or `AGENTS.md`, printing each `file:line` and the count (0 required). This check is enabled by feature 12's build, when those files are gone.
- **AC-5** (architecture): `docs/architecture.md` has *Parts* (dot, profiles, packages, home packages, system folders, kde keys, kde-theme, claude-config, hooks, tests), *Flows* (bootstrap, install, sync, status, each as the steps in order), *Invariants* (each one line with its spec and AC, at least: stow `--no-folding`; nothing in `/etc` is a link; KDE keys only by name; no Global Theme apply; `!` lines never read or written; deny list on every commit; submodule pointer only when pushed; screenshots never in the repo; only listed packages installed; panels only with `--apply-layout`), and *Where decisions live* (scope, specs, this file).
- **AC-6** (AGENTS.md): its *Commands* section shows `dot bootstrap` and the tests, its *Context files* line points at `docs/architecture.md`; curated lines stay as they are.

## Feature design

**Value sourcing**:

| Action | Value | Source |
|---|---|---|
| README | folder descriptions | the folder itself and the spec that created it |
| README | install steps | `dot bootstrap` (0008) and `dot install` (0001) |
| architecture | invariants | the *Key invariants* sections of specs 0001 to 0008 |
| AC-2 check | folders to name | `git ls-files` and `.gitmodules` |
| AC-3 check | commands run | the marked README block |

**Key invariants**:
- The README's server install block is executed by a test; it cannot drift without the test failing.

**Security model**: the README names no secret paths beyond the ones `deny.list` already names publicly.

**Critical test scenarios**:
- Delete one package line from the README: `tests/readme.sh` prints it, `1 missing` (mutation check). Verifies **AC-2**.
- Break a command in the marked block: the container test fails in every image. Verifies **AC-3**.
- Grep check after feature 12. Verifies **AC-4**.

## Build plan

1. Write `docs/architecture.md` from the specs' invariants. Satisfies **AC-5**.
2. Rewrite `README.md` in the AC-1 order with the marked server block. Satisfies **AC-1**.
3. `tests/readme.sh` (folder walk, stale word grep behind a flag until feature 12). Satisfies **AC-2**, **AC-4**.
4. `tests/server-profile.sh` runs the marked block. Satisfies **AC-3**.
5. `AGENTS.md` Commands and Context files. Satisfies **AC-6**.

## Probes

None: no outside tool behaviour is assumed beyond what specs 0001 to 0008 probe.

## Consequences

**Positive**:
- One page to read before changing the repo; install steps proven in containers.

**Negative / tradeoffs**:
- The README is checked for coverage, not for good writing; the desktop half of the install is not executed by any test (no Plasma in a container).

**Neutral**:
- Builds after features 7 to 10, so it documents what exists.

## Follow-up

- [ ] Feature 12 turns on the AC-4 stale word check.
