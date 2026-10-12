# Verify: KDE settings · spec 0004 · updated 2026-10-11
_Steps derived from spec 0004 acceptance criteria. `/check verify` runs these; `/test` locks the durable ones._

## Commands
- [ ] `tests/dot-status.sh` -> every line `ok`, exit 0 -> AC-2, AC-4, AC-6, AC-8, AC-10
- [ ] `./dot status` on this desktop -> no `is not in allow.list` line, no `differs from the repo` line under `kde:` -> AC-7
- [ ] `diff <(grep -vE '^[[:space:]]*(#|$|!)' kde/allow.list | wc -l) <(echo 77)` -> no output; every kept key from the spec's *Kept keys* table is one line -> AC-1
- [ ] `grep -c '^!' kde/allow.list` -> one line per row of *Left out keys* (`Colors:Header/Inactive` is covered by `!kdeglobals Colors:Header`, nested groups included) -> AC-2
- [ ] `grep -rn 'lookandfeel\|LookAndFeelPackage' dot kde/allow.list` -> only the `!kdeglobals KDE LookAndFeelPackage` line and the AC-5 comment, no tool call -> AC-5
- [ ] `./dot install desktop -n` with `DISPLAY` set and a repo `ColorScheme` that differs from the live one -> `kde     apply colorscheme <v> would run` -> AC-3
- [ ] Change a Dolphin setting not in the list (for example the compact view preview size, which adds `[CompactMode] PreviewSize`; not anything under the left out `[General]`), run `./dot status` -> names the key and exits 1; add a `!` line -> `all good` -> AC-6, AC-7

## Value sourcing
- [ ] Plain key: change `klipperrc General MaxClipItems` live to 5, run `./dot install desktop` -> live value is back to the repo's `1` -> install reads the value from `kde/<rcfile>`
- [ ] Apply key: theme name passed to the tool is the repo value (`ColorScheme=MacTahoeDark` in `kde/kdeglobals`), not the live one; dry run line names the repo value
- [ ] Installed check: a scheme not in `plasma-apply-colorscheme --list-schemes` prints `kde: colorscheme theme <v> is not installed, skipped`; a cursor is matched by its `[id]` in `plasma-apply-cursortheme --list-themes`; icons by folder under `~/.local/share/icons` or `/usr/share/icons`
- [ ] Unlisted check reads the live file under `$XDG_CONFIG_HOME` (set it to a throwaway folder and the check follows it, as `tests/dot-status.sh` does)
- [ ] Shortcut rule: a `kglobalshortcutsrc` key whose first field equals its second is not reported; change the first field and it is

## UI / manual (AC-9, throwaway user)
Run the setup script (creates `dottest`, copies the theme folders, clones the repo), log in to Plasma as `dottest`, run `~/dotfiles/dot install desktop`, log out and back in, then check:
- [ ] MacTahoeDark colors in Dolphin and in a GTK app -> AC-3, AC-9
- [ ] MacTahoe plasma theme on the panel -> AC-9
- [ ] Papirus-Dark-Real icons -> AC-3, AC-9
- [ ] WhiteSur cursor -> AC-3, AC-9
- [ ] Kvantum style on a Qt app (needs the `kvantum` package) -> AC-9
- [ ] Window buttons on the left with MacTahoe title bars -> AC-9
- [ ] Inter fonts (needs the Inter font package) -> AC-9
- [ ] Meta+Up maximizes right after install, before logging out, and still after the relogin (`busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel shortcut as 4 kwin "Window Maximize" "" ""` prints `ai 2 285212691 285212694`) -> AC-1, AC-9, AC-11
- [ ] Look at the theme checks only after a full log out and log in (KWin and plasmashell read them at start; `loginctl list-sessions` shows a new session) -> AC-9
- [ ] Touchpad natural scroll and 0.3 scroll speed -> AC-9
- [ ] Suspend after 5 minutes on battery (System Settings, Power) -> AC-9
- [ ] Clipboard keeps one item -> AC-9
- [ ] Dolphin without a menu bar -> AC-9
- [ ] Empty session at log in -> AC-9
- [ ] Before copying the theme folders (or after removing one): install prints a skipped line per missing theme, writes the other keys, exits 0, and `dot status` reports the theme keys as differing -> AC-4
- [ ] Delete the user afterwards with the cleanup script -> AC-9

## Acceptance-criteria coverage
- AC-1: allow.list line count, Meta+Up check · AC-2: `!` count, tests · AC-3: dry run line, throwaway theme checks · AC-4: tests, missing theme manual step · AC-5: grep · AC-6: tests, Dolphin tweak · AC-7: `dot status` · AC-8: privacy sweep in tests · AC-9: throwaway user checklist · AC-10: `tests/dot-status.sh`
