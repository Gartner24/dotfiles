# 0010. Retire the old scripts: rationale

Decision record for [index.md](index.md).

## Context

0001 chose a strangler migration: old scripts keep working while each program moves, and feature 12 deletes them last. Scope row 12: "the old scripts are gone and nothing in the repo or README points to them". `git grep` on 2026-10-14 finds the names in `AGENTS.md`, `README.md`, `profiles/server`, `install.sh` itself, the scope and specs 0001 and 0003.

## Options considered

### Option 1: job by job coverage table, then delete, then a repo wide word check (chosen)
- Pros: nothing the old script did is lost silently; the "nothing points to them" claim is counted.
- Cons: the check needs an exception list (docs, submodules).

### Option 2: delete now
- Pros: immediate.
- Cons: features 8 and 10 are not built; a new machine would have no installer.

### Option 3: keep `install.sh` as a thin wrapper that calls `dot bootstrap`
- Pros: old habits keep working.
- Cons: two names for one thing; the scope asks for removal.

## Rationale

The Done when is a universal claim ("nothing points to them"), so it gets a corpus walk with a count. The coverage table turns "the new scripts cover everything" into rows that each name a tested replacement.

## Decided without asking (2026-10-14)

1. **Delete or wrap.** Options: delete; keep a wrapper. Picked: delete (Option 1); the scope says gone.
2. **What "nothing in the repo points to them" covers.** Options: every tracked file; every file outside `docs/`. Picked: outside `docs/`. Specs and scope are history and must keep naming what they replaced.
3. **Submodules.** `kde-theme/install.sh` and claude-config's `install.sh` are their own installers with the same file name; they are excluded from the check.
4. **NVM.** Options: keep installing it for old projects; drop. Picked: drop; `.zshrc` moved to mise in March and `home/mise` pins node.
5. **The `--sync` mode.** Options: a `dot` subcommand; document `git pull` then `dot install`. Picked: document it; two existing commands do it.
6. **Order.** After features 8 and 10, as the scope orders, since they carry the replacements.
