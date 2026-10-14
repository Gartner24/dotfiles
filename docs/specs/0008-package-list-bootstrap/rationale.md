# 0008. Package list and bootstrap: rationale

Decision record for [index.md](index.md).

## Context

0002 settled what is on the install list and left the file format to this feature ("Feature 10 picks the file format the installer reads"). 0003 settled the Debian and Ubuntu mapping and the rules: mise fallback into a machine local file, vendor repos with keyrings, skip with a note when nothing packages a tool. The old `install.sh` installs a short hardcoded list, NVM and Oh My Zsh everywhere. Scope row 10 asks that install offers every program on the list, servers get only server items, and sync flags programs installed since the list was reviewed.

## Options considered

### Option 1: plain text lists plus a `dot bootstrap` command (chosen)
- Pros: `grep` and `sort` work on them; the same parser serves bootstrap and the unreviewed check; one entry point.
- Cons: a small parser in bash.

### Option 2: a structured file (TOML or YAML)
- Pros: richer fields.
- Cons: needs a parser that is not on a stock server; `dot` is bash.

### Option 3: keep `install.sh` and feed it the lists
- Pros: no new command.
- Cons: feature 12 deletes `install.sh`; two entry points with different profile logic.

## Rationale

The list has three fields per entry and a tag; plain lines carry that. Bootstrap belongs in `dot` because it ends by running `dot install`, and feature 12 removes the old script.

## Decided without asking (2026-10-14)

1. **File format.** Options: plain `<source> <name> [hw:tag]` lines; TOML; one file per source. Picked: plain lines, one file per profile (Option 1). The apt mapping stays a table (TSV) because it has a column per release.
2. **Entry point.** Options: `dot bootstrap`; a new `bootstrap.sh`; keep `install.sh`. Picked: `dot bootstrap`.
3. **How to get Plasma without Discover.** Options: `plasma-meta` then remove two packages (it depends on them, so removal breaks it); the `plasma` group with `--ignore`; the group expanded and filtered. Picked: expanded and filtered; P1 showed `--ignore` does not drop group members in a non interactive run. Excluded also: `plasma-bigscreen` (not installed today), `kwin-x11`, `kgamma`, `oxygen-cursors` (0002 dropped them), `wacomtablet` (kept as a hardware line).
4. **Hardware packages.** Options: install all; ask per tag; skip unless a flag. Picked: ask per tag, default no; without a terminal they are skipped.
5. **How many questions.** Options: one per source; one for everything plus one per hardware tag. Picked: one plus one per tag, after printing the whole plan.
6. **yay bootstrap.** Options: `yay` from its AUR git (`yay-bin`, prebuilt); `yay` source build; `paru`. Picked: `yay-bin`, as 0002 says yay from its git repo; the binary build avoids pulling Go.
7. **Services.** Options: list in a separate file; `service` lines in the profile files. Picked: `service` lines; earlyoom (feature 9), keyd (hw), bluetooth and docker are enabled today (0007 P2). `sddm` is part of the base install (0002 *Base reference*).
8. **Unreviewed check: status, sync, or both?** Options: status only; sync only (the scope says sync); both. Picked: both, status counts it as a problem like 0004's unlisted KDE keys, sync only prints.
9. **pipx and flatpak in the unreviewed check.** Options: pacman only; all three. Picked: all three; each has a one line listing command.
10. **Version floors (0003 Follow-up).** Options: compare versions at run time; mark the old releases `mise` in the table. Picked: table cells (zoxide on D12 and U22, gh on U22).
11. **gh credential helper.** Options: `/usr/bin/gh` per machine; `gh` from `PATH` everywhere. Picked: `PATH`, one line for both (scope note on feature 10).
12. **Oh My Zsh on the desktop.** Options: keep cloning it as `install.sh` does; a package. Picked: keep cloning (0003 Follow-up: full Oh My Zsh only on desktop), moved into bootstrap.
13. **Old downloaded binaries.** Options: bootstrap deletes them; a Follow-up for you. Picked: Follow-up; bootstrap never deletes.
14. **Desktop end to end test.** Options: container (no Plasma); VM; dry run plus your next new machine. Picked: dry run here, real run waits on you (P4).
