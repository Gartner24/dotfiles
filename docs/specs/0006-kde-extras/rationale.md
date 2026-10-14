# 0006. KDE extras: rationale

Decision record for [index.md](index.md).

## Context

Spec 0001 AC-13 decided the shape: your custom look is its own public repo, a submodule at `kde-theme/`, with credits, a license compatible with its upstreams, a link mode and an opt in panel layout. Spec 0004 left panels and wallpaper to this feature, and spec 0005 made the whole desktop screenshot this feature's closing test.

What is installed today (read 2026-10-14): MacTahoe-kde, MacTahoe icons (unused since you switched to Papirus-Dark-Real) and WhiteSur cursors from vinceliuice's GitHub (memory `kde-mac-theme`: the AUR copies were stale); AndromedaLauncher (GitHub EliverLara/AndromedaLauncher, LICENSE present) and KDE Control Station (EliverLara/kde-control-station, plasma6 branch, GPLv3) as plasmoids in `~/.local/share/plasma/plasmoids/`; two bottom panels (ids 3 and 42) with identical applets; slideshows from `~/Pictures/Wallpapers/screen-a` and `screen-b`.

## Options considered

### Option 1: own code in the theme repo, upstream fetched at pinned commits, panels by desktop script (chosen)
- Pros: nothing redistributed, so the license check reduces to your own code plus credits; reproducible versions; panels built from values, not from a file keyed by numeric ids.
- Cons: network needed at install; pins to maintain.

### Option 2: vendor the theme files into the theme repo
- Pros: offline install.
- Cons: redistributes LGPL and GPL theme files (license and attribution work per file); hundreds of SVGs in git; updates are manual copies.

### Option 3: copy `plasma-org.kde.plasma.desktop-appletsrc` whole
- Pros: exact copy of today.
- Cons: keyed by containment and screen ids a new machine does not share; holds desktop icon positions with file names (`Unconfirmed 965155.crdownload`, PDF names), a privacy leak in a public repo.

## Rationale

Your own work is small and is what makes the look yours; the rest already has upstream homes. Pinning commits gives the same result as copying without owning anyone else's files. Plasma's own scripting interface is the supported way to build panels and is what you used to edit them on 2026-09-30.

## Decided without asking (2026-10-14)

1. **Keep 0001's separate public repo, or a plain folder in dotfiles?** Options: submodule `Gartner24/kde-theme` (0001 AC-13); a `kde-theme/` folder inside dotfiles; keep under `kde/`. Picked: the submodule, as 0001 decided and as you asked (claude-config "child repo like the nvim and KDE ones", 2026-10-11). Creating the GitHub repo and its first push wait on you.
2. **Where theme files come from.** Options: vendor copies; AUR packages; upstream git at pinned commits. Picked: pinned upstream (Option 1). AUR copies were stale on 2026-09-30.
3. **Which upstreams.** Options: everything installed; only what is used. Picked: only used: MacTahoe-kde, WhiteSur-cursors, AndromedaLauncher, kde-control-station. MacTahoe icons are dropped (you replaced them with Papirus-Dark-Real); Papirus comes from the `papirus-icon-theme` package.
4. **License of the theme repo.** Options: MIT; GPL-2.0-or-later; GPL-3.0-or-later. Picked: GPL-3.0-or-later. Compatible with LGPL-3.0 MacTahoe and GPLv3 KDE Control Station, and with KDE's GPL-2.0-or-later QML the dock imports.
5. **How panels are restored.** Options: Plasma desktop script; copy the applets file; a Global Theme `layout.js` applied with `plasma-apply-lookandfeel`. Picked: desktop script run through `evaluateScript`. The copy leaks file names (Option 3); a Global Theme apply is forbidden by 0004 AC-5.
6. **When panels are replaced.** Options: every install; only with `--apply-layout`. Picked: only with the flag (0001 AC-13); a plain install on this machine must never reset your panels.
7. **Wallpaper pictures.** Options: commit them; commit nothing and point at `~/Pictures/Wallpapers/screen-a|b`; switch to a stock wallpaper. Picked: point at the folders. Pictures are personal files and large; the slideshow settings are what you chose.
8. **Mac Dock launcher list.** Options: as today including the two Brave web app ids; drop the web apps. Picked: screen 0's list on every screen, including the web app ids; they name web apps, not accounts. Screen 1's order (Settings first) is not kept. Whether the dock hides a launcher whose app is missing is unconfirmed; the AC-8 screenshot shows it.
9. **Launcher favourites.** Options: restore from `kactivitymanagerd-statsrc`; skip. Picked: skip. They are keyed by widget instance id, which the script creates fresh.
10. **Where the pacman hook goes.** Options: inside the theme repo with its own sudo step; dotfiles `system/real-app-icons/`. Picked: `system/`, so the only sudo path is `dot`'s diff and ask (0001 AC-7). This adjusts 0001's Neutral line that the hook leaves for the theme repo.
11. **Order inside `dot install`.** Options: theme installer after KDE keys (as 0001 listed); before. Picked: before, so 0004's apply tools find the themes and stop printing skipped lines.
12. **Upstream failure.** Options: stop the install; skip that upstream and continue. Picked: skip, print, exit 1 at the end, matching 0004 AC-4's skipped style.
