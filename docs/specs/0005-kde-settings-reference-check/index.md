# 0005. KDE settings fix: tell KDE about each write, and judge the restore against screenshots of the real desktop

**Date**: 2026-10-14
**Status**: Proposed
**Paths:** `dot`, `tests/dot-status.sh`, `tests/kde-shots.sh`, `tests/kde-user.sh`, `docs/specs/0004-kde-settings-keys/verify.md`
**Amends**: [0004](../0004-kde-settings-keys/index.md) (AC-9 replaced, AC-12 to AC-15 added). Feature 7.

## Summary

Feature 7's real test (spec 0004 AC-9: a throwaway user, `dottest`, restored from the repo) failed: you said the fresh user "did not look like the real desktop" ("the bar and things I configured aren't working", 2026-10-12). A copy of that user's `~/.config` (`~/dottest-config`, taken 2026-10-11 21:33) was compared with yours on 2026-10-14. Every kept key in `kde/allow.list` had arrived. What was different falls in two groups:

1. **Owned by feature 7, broken:** GTK apps (programs built on the GTK toolkit, such as Firefox, GIMP or zenity) kept their window buttons on the right and the Noto Sans font (`gtk-3.0/settings.ini`: `gtk-decoration-layout=icon:minimize,maximize,close`, `gtk-font-name=Noto Sans, 10`; yours: `close,minimize,maximize:` and `Inter, 10`). Cause: `dot` writes keys with `kwriteconfig6` without `--notify`, so KDE's GTK bridge (the `gtkconfig` module inside the `kded6` background service, which copies KDE fonts and button order into GTK's files when it hears of a change) never heard of the change.
2. **Owned by feature 8, not built yet:** the bottom panel with the Mac Dock, launcher, tray and clock, and the wallpaper slideshow (`plasma-org.kde.plasma.desktop-appletsrc` and `plasmashellrc` differ completely). That is "the bar".

The checklist in 0004 also judged each item by memory ("MacTahoe plasma theme on the panel"), so nobody could say exactly what looked wrong. This spec makes the judge a set of screenshots of your real desktop, taken the same way in both sessions and compared side by side, with an explicit list of differences that are allowed.

## What you're agreeing to

- `dot install` tells KDE about every setting it writes, so GTK apps follow your fonts and left side window buttons without a re-login.
- Before the next test you take a fixed set of screenshots on your own desktop with one script; they stay on your machine, never in the public repo.
- The throwaway user takes the same screenshots after the restore; a difference not on the allowed list fails the test.
- Feature 7 is judged only on its own windows (colors, icons, cursor, fonts, title bars, GTK, Dolphin); the panel, dock and wallpaper are judged by feature 8.
- The throwaway user scripts move into the repo (`tests/kde-user.sh`), and cleanup also deletes the old `~/dottest-config` copy.

Context, options and rationale: [rationale.md](rationale.md).

## Requirements

**User stories**:
- As the owner, I want a fresh KDE user restored from the repo to look like my desktop, judged against pictures of my desktop, not against a remembered checklist.
- As the owner, I want GTK apps restored with the same fonts and button side as Qt apps.

**Acceptance criteria**:
- **AC-12** (notify): every `kwriteconfig6` call `dot install` makes for a kept key passes `--notify`. `dot sync` writes into the repo copy and never passes it. `tests/dot-status.sh` checks both, by putting a `kwriteconfig6` stand-in first on `PATH` that logs its arguments.
- **AC-13** (capture script): `tests/kde-shots.sh <outdir>` takes the scenes in *Scenes* below with `spectacle -b -n` (spectacle, KDE's screenshot tool; `-b` no window, `-n` no notification), one PNG per scene named `<scene>.png`, opening and closing each window itself. It refuses to run without a Plasma session (`WAYLAND_DISPLAY` unset) and refuses an `<outdir>` inside the repo. It prints the folder and the scene count at the end.
- **AC-14** (reference set): a reference set exists at `~/Pictures/dotfiles-reference/<YYYY-MM-DD>/` taken on your own desktop with `tests/kde-shots.sh`, and nothing from it is committed (the script refuses a repo path, and `deny.list` gains the path pattern `^([^ ="']*/)?dotfiles-reference/`, anchored like its other file patterns).
- **AC-9** (replaces 0004 AC-9): `tests/kde-user.sh setup` creates the throwaway user `dottest`, copies the theme folders (until feature 8 installs them) and clones the repo from a bundle; you log in as `dottest`, run `~/dotfiles/dot install desktop`, log out and back in, run `~/dotfiles/tests/kde-shots.sh /tmp/dottest-shots`. Comparing each feature 7 scene with the reference finds no difference outside *Allowed differences*. The comparison is written to `docs/specs/0004-kde-settings-keys/verify.md` as one row per scene (scene, same or the difference seen). The items a picture cannot show stay as 0004's checklist has them: Meta+Up maximizes (before and after the relogin), touchpad natural scroll and 0.3 speed, suspend after 5 minutes on battery, clipboard keeps one item, empty session at log in. `tests/kde-user.sh cleanup` deletes the user, its home and `~/dottest-config`.
- **AC-15** (GTK follows): in the `dottest` session right after `dot install desktop` and before any log out, `~/.config/gtk-3.0/settings.ini` holds `gtk-decoration-layout=close,minimize,maximize:` and `gtk-font-name=Inter,  10` (two spaces, as KDE writes it).

## Feature design

**Scenes** (fixed content, so both sets differ only where the setup differs):

| Scene | Owner | How the script makes it |
|---|---|---|
| `dolphin` | feature 7 | `dolphin --new-window /usr/share/wallpapers`, active window shot (`-a`), with pointer (`-p`): colors, Kvantum style, icons, fonts, title bar buttons on the left, no menu bar, cursor |
| `gtk` | feature 7 | `zenity --info --text "dotfiles reference"`, active window shot: GTK font and button side |
| `fonts` | feature 7 | `kcmshell6 kcm_fonts`, active window shot: the font settings page |
| `desktop-<n>` | feature 8 | each screen with every window minimized (`-m` per screen, `qdbus6 org.kde.KWin /KWin org.kde.KWin.showDesktop true` first): panel, dock, tray, clock, wallpaper |

Each window gets 2 seconds to draw (`-d 2000`) and is closed after its shot.

**Allowed differences** (never a failure): the clock time; window contents that change by themselves (none in these scenes); the wallpaper picture inside a slideshow (it must come from the same folder); screen scale, which lives in `kwinoutputconfig.json` and is per monitor, not tracked (0004).

**Value sourcing**:

| Action | Value | Source |
|---|---|---|
| install | whether listeners are told | always, `--notify` on every live write (AC-12) |
| capture | scene list | the *Scenes* table above |
| capture | reference folder | `~/Pictures/dotfiles-reference/<date of capture>/` (AC-14) |
| compare | what counts as a pass | *Allowed differences* above |
| compare | who judges | `/check verify` reads both PNGs of each scene and writes the row; you confirm the table |
| user setup | theme folders copied | the same list as `~/ac9-setup.sh` today (color scheme, plasma theme, two icon folders, Aurorae, Kvantum), dropped once feature 8 installs them |

**Key invariants**:
- No screenshot is ever written inside the repo.
- `dot sync` never notifies (it writes a repo copy, nobody listens to it).
- Install still never applies a Global Theme (0004 AC-5 unchanged).

**Security model**: screenshots show window titles and folder names, so they stay outside the public repo (AC-14). The scenes open only system folders (`/usr/share/wallpapers`) so they show nothing personal. The user scripts need sudo to create and delete `dottest`; they print each sudo step first.

**Critical test scenarios**:
- `tests/dot-status.sh`: install logs `--notify` on each kept key write, sync logs none. Remove `--notify` from `kcfg` and the case fails (mutation check). Verifies **AC-12**.
- `tests/kde-shots.sh` with `WAYLAND_DISPLAY` unset exits 1 with a message; with `<outdir>` inside the repo exits 1. Verifies **AC-13**, **AC-14**.
- Real run on your desktop: 3 feature 7 scenes plus one `desktop-<n>` per screen. Verifies **AC-13**, **AC-14**.
- `dottest` run, compared scene by scene. Verifies **AC-9**, **AC-15**.

## Build plan

1. `kcfg write` gains a notify flag; `install_kde` passes it, `sync_kde` does not. Add the `PATH` stand-in case to `tests/dot-status.sh`. Satisfies **AC-12**.
2. Write `tests/kde-shots.sh` (session and repo path guards, the scene table, close each window). Add the `dotfiles-reference/` path pattern to `deny.list`. Satisfies **AC-13**, **AC-14**.
3. Move `~/ac9-setup.sh` and `~/ac9-cleanup.sh` into `tests/kde-user.sh setup|cleanup`; cleanup also removes `~/dottest-config`. Satisfies **AC-9** (tooling).
4. You take the reference set on your desktop (`tests/kde-shots.sh ~/Pictures/dotfiles-reference/$(date +%F)`). Satisfies **AC-14**.
5. You run the `dottest` check; `/check verify` compares the feature 7 scenes and writes the table. Satisfies **AC-9**, **AC-15**.

## Probes

None run yet; each is listed for the build or for you, since they need a Plasma session, sudo or a new user.

| Probe | Command | Expect | Who |
|---|---|---|---|
| P1 GTK bridge is loaded here | `busctl --user call org.kde.kded6 /kded org.kde.kded6 loadedModules` | contains `gtkconfig` (ran read only 2026-10-14: it does) | done |
| P2 `--notify` reaches gtkconfig | in `dottest`: `dot install desktop`, then `grep -E 'decoration-layout|font-name' ~/.config/gtk-3.0/settings.ini` | the AC-15 values | you (needs `dottest`) |
| P3 spectacle options | `spectacle --help` | `-b -n -a -m -p -d -o` exist (ran 2026-10-14: they do) | done |
| P4 shots under Wayland | `tests/kde-shots.sh /tmp/shots-probe` on your desktop | one PNG per scene, none blank | you (real desktop) |

If P2 fails (the GTK file is unchanged after a notified write), the build stops and asks: the fallback is restarting the `gtkconfig` module, which this spec does not decide.

## Consequences

**Positive**:
- A failed restore names the scene and the difference, not a feeling.
- GTK apps match Qt apps right after install.

**Negative / tradeoffs**:
- The reference set is a snapshot; after a deliberate change to your look you retake it.
- The comparison is a judgement on two pictures (by `/check verify`, confirmed by you), not a pixel diff; a pixel diff fails on the clock and the slideshow every time.

**Neutral**:
- `kde/allow.list` is unchanged; nothing was missing from it.

## Follow-up

- [ ] Feature 8 (spec 0006): the `desktop-<n>` scenes are its closing test, and its theme installer replaces the hand copied theme folders in `tests/kde-user.sh setup`.
- [ ] The splash screen differs (your `kdedefaults/package` says Breeze Dark from a Global Theme applied long ago, a new user's says Breeze). Not in any screenshot and not tracked; pull it in only if you notice it at login.
- [ ] Scope feature 7 *Done when* says "matches your current desktop"; per this spec that is the feature 7 scenes, and the panel half closes with feature 8. Reword the line when you next replan.
