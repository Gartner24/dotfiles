# 0005. KDE settings fix: rationale

Decision record for [index.md](index.md).

## Context

Spec 0004's AC-9 run on 2026-10-11 was judged twice and failed both times. The first time the shortcuts were reset by the running KWin (fixed by 0004 AC-11). The second time you said the fresh user did not look like your desktop. The personal scope (row 15, 2026-10-12) says to use screenshots of your real desktop as the reference.

Evidence used here, all read only on 2026-10-14:
- `~/dottest-config`, a copy of the `dottest` user's `~/.config` from the second run, diffed against your `~/.config`. `kdeglobals`, `kwinrc`, `kcminputrc`, `plasmarc` and `Kvantum/kvantum.kvconfig` match on every kept key; only left out keys differ (`LookAndFeelPackage`, tiling UUIDs, the HDR group, wallpaper paths).
- `gtk-3.0/settings.ini` differs on the button order and the font (index.md, Summary).
- `plasma-org.kde.plasma.desktop-appletsrc` and `plasmashellrc` differ completely: panels are feature 8.
- `kdedefaults/package`: Breeze for `dottest`, Breeze Dark for you.
- `dot` calls `kwriteconfig6` without `--notify` (`kcfg`, line 244); `kwriteconfig6 --help` lists `--notify` ("Notify applications of the change").
- The conductor note of 2026-10-12: "the bar and things I configured aren't working".

## Options considered

### Option 1: notify on write, screenshot reference, split the judgement by feature (chosen)
Fix the one real feature 7 bug, and make the test compare pictures of the same scenes.
- Pros: small code change; the test names what is wrong; feature 7 can close without waiting for feature 8.
- Cons: two picture sets to keep; the judgement is by eye.

### Option 2: build feature 8 first, then rerun one combined test
- Pros: one test covers everything you see.
- Cons: feature 7 stays open across another whole feature; a feature 7 bug would be found mixed with feature 8 ones.

### Option 3: pixel diff of the screenshots
- Pros: no judgement.
- Cons: the clock, the slideshow and font hinting fail it every run; masks would be more code than the rest of the spec.

## Rationale

The rc keys arrived; the visible failures were GTK (a missing notification) and the panel (not built yet). Fixing the notification is one flag. The test problem was that nobody could say what differed; fixed scenes with fixed content make the difference visible, and the allowed list says in advance which differences do not count.

## Decided without asking (2026-10-14)

You agreed that `/architect` picks the recommended option for every question in this sitting and records it here.

1. **What failed, and whose is it?** Options: all feature 7; all feature 8; split by evidence. Picked: split by evidence. The kept keys all arrived (diff above); GTK is feature 7's, the panel and wallpaper are feature 8's.
2. **How to make GTK follow?** Options: `kwriteconfig6 --notify` on each install write; restart the `gtkconfig` module after install; write `gtk-3.0/settings.ini` ourselves. Picked: `--notify`. It is the documented way KDE apps and System Settings tell listeners; writing GTK files ourselves would track a generated file that 0004 left out on purpose. Unconfirmed until probe P2 runs.
3. **Where do the reference screenshots live?** Options: in the repo under `docs/`; outside the repo. Picked: outside, `~/Pictures/dotfiles-reference/<date>/`. Screenshots show window titles and folders and the repo is public.
4. **Who takes them?** Options: by hand with any tool; one script for both sessions. Picked: one script (`tests/kde-shots.sh`), so both sets are taken the same way.
5. **Which scenes?** Options: whole screen only; a few fixed windows plus the whole screen. Picked: fixed windows (Dolphin on `/usr/share/wallpapers`, a zenity GTK dialog, the fonts settings page) plus one whole screen per monitor. Fixed system content keeps personal files out and makes the two sets comparable.
6. **How to compare?** Options: pixel diff; side by side judgement with an allowed differences list. Picked: judgement, written per scene by `/check verify` and confirmed by you (Option 3 above).
7. **Does feature 7 wait for feature 8?** Options: yes, one combined test; no, feature 7 judged on its scenes. Picked: no (Option 2 above). The desktop scenes become feature 8's closing test.
8. **The throwaway user scripts.** Options: keep `~/ac9-setup.sh` and `~/ac9-cleanup.sh` in your home; move them into the repo. Picked: into the repo as `tests/kde-user.sh setup|cleanup`, so the test can be repeated from a clone. Cleanup also removes `~/dottest-config`, which holds a copy of `dottest`'s KDE Connect private key.
9. **The Breeze vs Breeze Dark defaults layer (`kdedefaults`).** Options: apply the Breeze Dark Global Theme before the keys (contradicts 0004 AC-5); track `kdedefaults/` files; leave it. Picked: leave it. The only visible effect found is the login splash screen; recorded as a Follow-up.
10. **Scope wording.** The feature 7 *Done when* line is left as it is (this sitting only adds spec pointers and boxes); the spec's Follow-up says how it is read.
