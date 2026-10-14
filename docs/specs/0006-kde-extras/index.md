# 0006. KDE extras: the kde-theme submodule, pinned upstream themes, and a panel layout script

**Date**: 2026-10-14
**Status**: Proposed
**Paths:** `dot`, `kde-theme/**`, `.gitmodules`, `profiles/desktop`, `system/real-app-icons/**`, `install.sh`, `tests/kde-user.sh`, `tests/dot-status.sh`, `README.md`
**Builds**: [0001](../0001-repo-layout-linking/index.md) AC-13. Feature 8. Closing test from [0005](../0005-kde-settings-reference-check/index.md).

## Summary

Your look has three kinds of parts. Your own code: the Mac Dock plasmoid (a panel widget written in QML, `org.santiago.macdock`), the `real-app-icons` builder, and a panel layout. Other people's themes: MacTahoe (color scheme, plasma theme, title bars, Kvantum, wallpapers), WhiteSur cursors, Papirus icons (a package), and two panel widgets, AndromedaLauncher and KDE Control Station. And per screen state: your two bottom panels and the wallpaper slideshow. Spec 0001 AC-13 already decided that your own parts become a public repo `Gartner24/kde-theme`, pulled into dotfiles as a submodule (a repo inside a repo) at `kde-theme/`, with its own installer that `dot install desktop` calls. This spec fills that in: the theme repo holds only your code plus a pinned list of upstream sources its installer downloads, never copies of other people's themes; the panels come from a Plasma desktop script (a JavaScript file Plasma runs to build panels) that you apply on purpose with `--apply-layout`.

## What you're agreeing to

- A new public repo `Gartner24/kde-theme` with your dock, `real-app-icons`, the panel script and a credits file; you create it on GitHub and approve its first push.
- On a new desktop, `dot install desktop` downloads MacTahoe, WhiteSur cursors and the two launcher widgets at fixed versions, installs them for your user, and links your dock and icon builder.
- Your panels (launcher, dock, tray, control station, clock, one per screen) are rebuilt only when you pass `--apply-layout`, because it replaces the panels you have.
- The wallpaper slideshow points at `~/Pictures/Wallpapers/screen-a` and `screen-b`; the pictures themselves stay out of the repo.
- The pacman hook moves to `system/real-app-icons/` and is installed like keyd: diff first, then sudo.

Context, options and rationale: [rationale.md](rationale.md).

## Requirements

**User stories**:
- As the owner, I want my dock, icons and panels back on a new desktop from the repo, not from a backup archive.
- As the owner of a public repo, I want to publish only my own code and credit the themes I build on.

**Acceptance criteria**:
- **AC-1** (theme repo): `kde-theme/` is a submodule of `Gartner24/kde-theme` (desktop profile only, listed in `profiles/desktop`), holding `plasmoids/org.santiago.macdock/`, `bin/real-app-icons`, `layout/panels.js`, `upstream.list`, `install.sh`, `CREDITS.md` and `LICENSE` (GPL-3.0-or-later). It holds no file copied from an upstream theme. The old root paths `.local/share/plasma/plasmoids/org.santiago.macdock/` and `.local/bin/real-app-icons` leave dotfiles in the same change, and `install.sh` stops linking them.
- **AC-2** (pinned upstream): `upstream.list` has one line per source: `<name> <git url> <commit> <install command>`. Rows: MacTahoe-kde (`./install.sh -c dark`), WhiteSur-cursors (`./install.sh`), AndromedaLauncher and kde-control-station (plasma6 branch) (`kpackagetool6 -t Plasma/Applet -u` when present, else `-i`). Commits are the ones that match what is installed today, found in the build. `CREDITS.md` names each row with its license and URL.
- **AC-3** (installer): `kde-theme/install.sh [--link] [--apply-layout] [--dry-run]` clones each upstream at its commit into `~/.cache/kde-theme/<name>` (reusing a clone already at that commit), runs its install command as your user (never sudo), links the dock into `~/.local/share/plasma/plasmoids/` and `real-app-icons` into `~/.local/bin/` (`--link`, so edits stay live), runs `real-app-icons` once, and with `--apply-layout` runs `layout/panels.js`. A failed clone or upstream install prints `kde-theme: <name> failed, skipped` and continues; the exit code is 1 when anything was skipped. `--dry-run` prints each step and changes nothing.
- **AC-4** (dot calls it): `dot install desktop` initializes `kde-theme` and runs `kde-theme/install.sh --link` (plus `--dry-run` under `-n`, plus `--apply-layout` when `dot install` got it) before it writes KDE keys, so 0004's apply tools find the themes. `dot install --apply-layout` is accepted only with the desktop profile. The server profile never initializes `kde-theme` (0003 AC-7, unchanged).
- **AC-5** (panels): `layout/panels.js`, run through `qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript`, removes existing panels and adds, on every screen, one bottom panel: floating, height 72, fit content, opaque, dodge windows, applets in order AndromedaLauncher (grid, floating, bottom centre, no glow, no greeting, icon `view-app-grid-symbolic`), `org.santiago.macdock` (the launcher list in *Panel values*), margins separator, system tray, KdeControlStation, digital clock (Inter, 11, weight 500). It sets each screen's wallpaper to the slideshow plugin, fill mode 2, interval 3600 s, folder `~/Pictures/Wallpapers/screen-a` for screen 0 and `screen-b` for screen 1, and leaves a screen's wallpaper unchanged when its folder is missing. The script holds no `/home/` path; it builds paths from `userDataPath()` or the home folder at run time.
- **AC-6** (pacman hook): `kde/real-app-icons.hook` moves to `system/real-app-icons/etc/pacman.d/hooks/real-app-icons.hook`, `real-app-icons` is listed in `profiles/desktop`, and it installs through 0001 AC-7 (diff, ask, `sudo install`). Its comment line points at the new path.
- **AC-7** (tests): `tests/dot-status.sh` covers that `dot install desktop -n` prints the theme installer's dry run line before the first `kde` line, and that `--apply-layout` with the server profile exits 2. `kde-theme` has its own `tests/install.sh` that runs `install.sh --dry-run` against a throwaway `HOME` and checks every `upstream.list` row prints a clone and an install line.
- **AC-8** (closing test): on the `dottest` user from 0005 with no theme folders copied by hand (setup copies only `~/Pictures/Wallpapers`), `dot install desktop --apply-layout`, log out and in, `tests/kde-shots.sh`: every scene, feature 7's and the `desktop-<n>` ones, matches the reference set except the allowed differences of 0005. After a `pacman -S` that adds an app icon, the new app's real logo shows in Papirus-Dark-Real.

## Feature design

**Theme repo layout**:
```
kde-theme/
  install.sh                 # --link --apply-layout --dry-run
  upstream.list              # name url commit install-command
  plasmoids/org.santiago.macdock/
  bin/real-app-icons
  layout/panels.js           # Plasma desktop script
  CREDITS.md  LICENSE  README.md
  tests/install.sh
```

**Panel values** (read from your live `plasma-org.kde.plasma.desktop-appletsrc` and `plasmashellrc`, 2026-10-14):

| Setting | Value |
|---|---|
| panel | location bottom, `floating=1`, `panelLengthMode=1` (fit content), `panelOpacity=1` (opaque), `panelVisibility=2` (dodge windows), thickness 72 |
| AndromedaLauncher | `activationIndicator=false`, `enableGlow=false`, `enableGreeting=false`, `floating=true`, `icon=view-app-grid-symbolic`, `launcherPosition=1`, `showItemsInGrid=true` |
| Mac Dock launchers | screen 0's list verbatim, on every screen: `applications:brave-kjbdgfilnfhdoflbpgamdcdgpehopbep-Default.desktop`, `applications:systemsettings.desktop`, `applications:brave-hnpfjngllnobngcgfapefoaidbinmjnm-Default.desktop`, `applications:spotify-launcher.desktop`, `preferred://browser`, `applications:com.mitchellh.ghostty.desktop`, `applications:org.telegram.desktop.desktop`, `file:///usr/share/applications/discord.desktop`, `applications:com.anthropic.Claude.desktop` (screen 1 differs today only in the order of the first two) |
| clock | `autoFontAndSize=false`, `fontFamily=Inter`, `fontSize=11`, `fontWeight=500` |
| wallpaper | `org.kde.slideshow`, `FillMode=2`, `SlideInterval=3600`, `SlideshowMode=0`, `SlidePaths` per screen as AC-5 |

**Value sourcing**:

| Action | Value | Source |
|---|---|---|
| install | which upstream, which version | `kde-theme/upstream.list` |
| install | upstream install flags | `upstream.list` (MacTahoe `-c dark`: memory of the 2026-09-30 install) |
| install | whether panels are replaced | `--apply-layout`, default off (0001 AC-13) |
| layout | panel and applet settings | *Panel values* above, from the live files |
| layout | wallpaper folders | `~/Pictures/Wallpapers/screen-a`, `screen-b` (live `SlidePaths`), home resolved at run time |
| hook | where it installs | `system/real-app-icons/etc/...` path (0001 AC-7) |
| icons | Papirus base | `papirus-icon-theme` package (0002 install list), built into Papirus-Dark-Real by `real-app-icons` |

**Key invariants**:
- No upstream theme file is committed to `kde-theme` or dotfiles.
- Panels change only with `--apply-layout`.
- Nothing in `kde-theme` runs sudo; the only system file (the hook) goes through `dot`'s system path.

**Security model**: upstream code runs as your user at a pinned commit, so a changed upstream cannot run new code until you move the pin. `CREDITS.md` and `LICENSE` make the public repo legal to share (0001 Follow-up on licenses). The layout script holds no paths, names or launcher favourites beyond the app ids listed.

**Critical test scenarios**:
- Dry run on this desktop prints clone, install and link lines and changes nothing. Verifies **AC-3**, **AC-4**.
- `dottest` full restore against the reference set. Verifies **AC-5**, **AC-8**.
- `dot install desktop -n` shows the hook diff from `system/real-app-icons`. Verifies **AC-6**.
- Repo check: `git -C kde-theme ls-files` has no `.svg`, `.colors`, `.kvconfig` or `metadata.json` outside `plasmoids/org.santiago.macdock/`. Verifies **AC-1**.

## Build plan

1. Create the theme repo locally (`~/kde-theme` worked in place, later moved under `dotfiles/kde-theme`): move the dock and `real-app-icons` in with their history (`git mv` in dotfiles, copy into the new repo), write `CREDITS.md`, `LICENSE`, `README.md`. Satisfies **AC-1** (content).
2. Find the commits that match what is installed (compare `~/.local/share/...` files with upstream history), write `upstream.list`, write `install.sh` with `--dry-run`, and `tests/install.sh`. Satisfies **AC-2**, **AC-3**, **AC-7**.
3. Write `layout/panels.js` from *Panel values*; dry check it by printing the script it would run. Satisfies **AC-5**.
4. You create `Gartner24/kde-theme` on GitHub and approve the first push. Waits on you.
5. Add it as a submodule at `kde-theme/`, list it in `profiles/desktop`; `dot install` calls the installer before KDE keys and accepts `--apply-layout`; drop the old links from `install.sh`. Add the `tests/dot-status.sh` cases. Satisfies **AC-1**, **AC-4**, **AC-7**.
6. Move the hook to `system/real-app-icons/`, add `real-app-icons` to `profiles/desktop`. Satisfies **AC-6**.
7. `tests/kde-user.sh setup` stops copying theme folders and copies `~/Pictures/Wallpapers` instead. You run the `dottest` check with `--apply-layout`; `/check verify` compares all scenes. Satisfies **AC-8**.

## Probes

Not run in this sitting (they download code, change the theme or need a session); the build runs P1 to P3 first and stops on a failure.

| Probe | Command | Expect |
|---|---|---|
| P1 MacTahoe-kde installs Kvantum, Aurorae, color scheme and wallpapers for one user | clone, read `install.sh -h`, then `./install.sh -c dark` into a throwaway `HOME` | the four folders appear under that `HOME` only |
| P2 the two widgets install from git | `kpackagetool6 -t Plasma/Applet -i <clone>` into a throwaway `HOME` (`XDG_DATA_HOME`) | `kpackagetool6 -l` lists them |
| P3 panel script runs | `qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "print(panels().length)"` on your desktop | prints 2 (read only) |
| P4 layout script end to end | in `dottest` only, with `--apply-layout` | panels as *Panel values* (you, in AC-8) |

## Consequences

**Positive**:
- The look installs from one command on a new desktop, at known upstream versions.
- Others can use your dock and layout; nothing in the public repo is someone else's file.

**Negative / tradeoffs**:
- A new desktop needs network access to GitHub for the themes.
- Moving a pin is a manual edit plus a test.
- Launcher favourites (kept per widget id in `kactivitymanagerd-statsrc`) are not restored; you pin them again.

**Neutral**:
- A third submodule (0001 named the cost).

## Follow-up

- [ ] Feature 10: `papirus-icon-theme`, `kvantum`, `inter-font` on the desktop list (already in 0002).
- [ ] Feature 11: README section for `kde-theme`.
- [ ] Panel colorizer: no presets today (0004); add to `upstream.list` only if you start using it.
