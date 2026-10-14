# 0011. claude-config as a submodule: rationale

Decision record for [index.md](index.md).

## Context

0001 AC-16 fixed the destination (`claude-config/`, both profiles, its own install and sync) and migration phase 5 said: once the branch is merged, `git submodule add` it, move the standalone clone aside, and point its users at the new path. The scope row for feature 1 has one open milestone, "claude-config as a submodule, called by dot install and sync (AC-16), after its branch is merged". On 2026-10-14 the runner branch is merged but claude-config is on `feat/release-4` with work for tonight's `wf run`, and the runner and three `~/.local/bin` links use `~/claude-config`.

## Options considered

### Option 1: move the working clone in, leave a symlink at the old path (chosen)
- Pros: one clone; nothing that names `~/claude-config` breaks; no lost local state (`.git/info/exclude` private lines, hooks, worktrees).
- Cons: the runner's trust list needs one `wf allow` (it resolves real paths).

### Option 2: fresh submodule clone, old clone moved aside (0001 phase 5 as written)
- Pros: a clean checkout.
- Cons: loses the clone's local only state (private exclude lines, hooks installed by its `install.sh`, any unpushed branch); every link and note must be changed.

### Option 3: no submodule; `dot install` clones claude-config to `~/claude-config` if missing
- Pros: no move at all.
- Cons: no pinned version in dotfiles; contradicts 0001 AC-16 and your 2026-10-11 ask for a child repo.

## Rationale

The submodule is decided; the open question was only how to get there without breaking the runner. Moving the clone keeps everything that lives only in it, and the link keeps every old reference valid.

## Decided without asking (2026-10-14)

1. **Fresh clone or move the existing one.** Options: fresh clone, old one aside; move the existing clone. Picked: move (Option 1).
2. **Keep the old path.** Options: update every reference; a symlink `~/claude-config -> dotfiles/claude-config`. Picked: the symlink; references in notes, `CLAUDE.md` and links keep working.
3. **`absorbgitdirs` (move its `.git` into dotfiles' `.git/modules`).** Options: absorb; leave it. Picked: leave it; absorbing rewrites worktree paths the runner uses, for no gain.
4. **When.** Options: now; after `feat/release-4` merges and no run is active. Picked: after, as AC-1 preconditions checked by a script.
5. **Who runs the move.** Options: the runner; you. Picked: you (it moves a repo the runner itself runs from).
6. **Runner trust.** Options: dotfiles edits `allowed.json`; you run `wf allow`. Picked: `wf allow`; dotfiles never writes `~/.config/wf/` and `deny.list` blocks it.
7. **install.sh failure.** Options: stop `dot install`; finish the rest then exit 1. Picked: finish then exit 1, so a Claude problem never leaves shell links half done.
8. **Profile.** Both, as 0001 AC-16. A server needs node, python3 and jq for claude-config's self checks; that stays claude-config's job.
