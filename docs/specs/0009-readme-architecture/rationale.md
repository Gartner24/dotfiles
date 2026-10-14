# 0009. README and architecture docs: rationale

Decision record for [index.md](index.md).

## Context

Scope row 11: "every folder in the repo is described and the install and sync steps in the README work as written". The README today mixes the old install (`install.sh`, WSL notes) with a *Layout* section for the new one. There is no `docs/architecture.md`; your spec gate rule says `/architect` reads it first when it exists and updates it when a decision changes an invariant.

## Options considered

### Option 1: README for use, `docs/architecture.md` for rules, both checked by tests (chosen)
- Pros: each file has one reader; the checks make "described" and "works as written" measurable.
- Cons: two files to keep current.

### Option 2: one long README with everything
- Pros: one file.
- Cons: the rules drown the install steps; `/architect` has no fixed place to read.

### Option 3: README only, no checks
- Pros: least work.
- Cons: "works as written" stays a claim; the old README is how it drifted.

## Rationale

The universal claim in the Done when ("every folder") needs a walk over every folder with a count; "works as written" needs the written steps to be executed. The architecture page is short and points at specs instead of repeating them.

## Decided without asking (2026-10-14)

1. **One file or two.** Options: README only; README plus `docs/architecture.md`. Picked: two (Option 1).
2. **How "every folder is described" is checked.** Options: by eye; a walk over `git ls-files` with a missing count. Picked: the walk (AC-2).
3. **How "steps work as written" is checked.** Options: by hand on a new machine; run the README's own block in the existing server containers. Picked: run the block (AC-3). The desktop half cannot run in a container and is covered by feature 10's dry run and your next new machine.
4. **Stale words check timing.** Options: now; after feature 12. Picked: after feature 12, since `install.sh` legitimately exists until then.
5. **WSL and Ubuntu desktop.** Options: keep the notes; drop them. Picked: drop; the scope dropped the Ubuntu/WSL path on 2026-10-11.
6. **Order of build.** Options: before features 7 to 10; after. Picked: after (the scope's slice order), so it documents what exists.
