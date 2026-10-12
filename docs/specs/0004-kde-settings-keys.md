# 0004. KDE settings: the kept keys, theme apply tools, and an unlisted key check

**Date**: 2026-10-11
**Status**: Proposed

## Summary

This spec fills `kde/allow.list` with the KDE settings you actually tuned (shortcuts, fonts, KWin buttons, mouse and touchpad, power, clipboard, Dolphin, Spectacle and the file dialog), and marks every other key in those files as left out on purpose. The color scheme, cursor and icon picks are restored by KDE's own apply tools instead of raw key writes, because writing the name alone does not recolor anything; the plasma theme and Kvantum theme are plain keys. `dot status` learns to list any new key that shows up in a tracked file and is not decided yet, so a setting you change next month does not silently stay off the repo. Panels and wallpaper stay with feature 8.

## Context

Spec 0001 already decided the mechanism: KDE rc files are never linked, `kde/allow.list` names each kept key, `dot sync` reads them with `kreadconfig6`, `dot install` writes them with `kwriteconfig6` and asks you to log out. It left one thing open (its Follow-up): which files and keys. Today the list holds two `kglobalshortcutsrc` keys.

A survey of your live `~/.config` on 2026-10-11 shaped the answer. `kwinrulesrc` is empty and `panel-colorizer/presets` is empty, so there are no window rules or colorizer presets to keep. Only four global shortcuts differ from KDE's defaults. Your look is assembled by hand: `LookAndFeelPackage` still says `org.kde.breezedark.desktop` while the color scheme, plasma theme, icons, cursor, Kvantum and Aurorae are MacTahoe, Papirus and WhiteSur, so applying a Global Theme (a bundle of all those picks) would overwrite your setup with Breeze Dark.

Two traps drive the rest. First, `kdeglobals` holds about 110 `[Colors:*]`, `[ColorEffects:*]` and `[WM]` color keys that KDE expands from the scheme when you pick it; copying `ColorScheme=MacTahoeDark` alone recolors nothing, and copying all 110 keys skips the GTK and window title updates the apply tool does. Second, an allow list only reads what it names, so any setting you tweak after today is lost on the next machine unless something tells you about it.

The repo is public. Several of these files mix preferences with paths and recent lists (Spectacle's last save location, a file dialog's recent URLs). Folder names can name clients, so no key holding a path, URL or recent list may reach the repo.

## Requirements

**User stories**:
- As the owner of this desktop, I want my KDE preferences restored on a new machine so that it feels like mine after one install and a log out.
- As the owner of a public repo, I want only named preference keys committed so that no path, client folder name, recent file or account ever leaks.
- As someone who keeps tweaking KDE, I want `dot status` to tell me about a setting I changed that the repo does not know about yet.

**Acceptance criteria**:
- **AC-1**: `kde/allow.list` holds exactly the kept keys in *Kept keys* below, one per line in the existing `<rcfile> <Group> <Key>` format (nested groups as `Group/Sub`, quoted when they contain spaces).
- **AC-2**: A line starting with `!` marks a left out key: `!<rcfile> <Group> <Key>`, or `!<rcfile> <Group>` (the whole group, including its nested groups). `dot sync` and `dot install` never read or write a `!` line. An allow line always wins: a `!` line only quiets the unlisted key check (AC-6). When an allow line and a `!` line cover the same key, `dot status` reports `dot: allow.list covers <rc> [<grp>] <key> twice` as a problem. Group names never contain `/` (it is the nesting separator). `kde/allow.list` holds the `!` lines in *Left out keys* below.
- **AC-3**: The three apply keys in *Theme apply* are installed by running their tool with the repo value, never by `kwriteconfig6`, and only when the repo value differs from the live one (the tool sets the key itself, so after a successful apply they match). Install writes every plain key first and runs the apply tools last. `dot sync` still reads apply keys like any other key. A dry run prints `kde     apply <what> <value> would run` instead of running it.
- **AC-4**: When an apply key's theme is not installed (the check in *Theme apply* fails), install skips that one tool, prints `kde: <what> theme <value> is not installed, skipped`, writes nothing for that key, and continues with the rest; install still exits 0. A dry run prints the same skipped line. When neither `WAYLAND_DISPLAY` nor `DISPLAY` is set, install runs no apply tool and prints `kde: theme apply needs a Plasma session, skipped` once. `dot status` then reports each skipped key as differing from the repo, as it does today.
- **AC-5**: Install never runs `plasma-apply-lookandfeel` and never writes `LookAndFeelPackage`.
- **AC-6**: `dot status` lists every key present in a tracked rc file (an rc file named by at least one non `!` line) that no allow line and no `!` line covers, as `kde: <rc> [<grp>] <key> is not in allow.list`, and counts each as a problem (non zero exit). It prints names only, never values. Parsing rules: skip comment and blank lines and any key before the first group; join nested groups `[A][B]` as `A/B`; strip a trailing `[$e]`, `[$i]` or `[$d]` marker from a key name; keep locale keys such as `Name[de]` as written (no decoding). The rc path is relative to `$XDG_CONFIG_HOME` on both sides (`Kvantum/kvantum.kvconfig`). For `kglobalshortcutsrc` a key counts only when its first field differs from its second, the fields being the raw value split at its first two unescaped commas and compared as plain text (a tab separated pair such as `Meta+Up\tMeta+PgUp` is one field); `_k_friendly_name` never counts.
- **AC-7**: On this machine, right after the build, `dot status` reports zero unlisted KDE keys: every key in every tracked file is kept or left out on purpose.
- **AC-8**: No file under `kde/` (excluding `allow.list` itself and `real-app-icons.hook`) contains `file:`, `/home/`, `/tmp/`, `http`, or a key named `Recent*` or ending in `Location`, in either a key name or a value; a check walks every committed file under `kde/` and prints the count of violations, which must be 0.
- **AC-9**: With the theme folders copied by hand into a throwaway user's `~/.local/share` and `~/.config/Kvantum`, logging that user into Plasma, cloning the repo, running `./dot install desktop`, then logging out and in, gives the checklist in *Critical test scenarios*. The user is deleted afterwards.
- **AC-10**: `tests/dot-status.sh` covers `!` parsing (both forms, and an allow plus `!` overlap reported), the unlisted key check (one unlisted key flagged, the same key with a `!` line not flagged, an unchanged default shortcut not flagged, a `[$i]` key matched by its bare name), that sync never writes a `!` key, and that a font value with commas and spaces round trips through sync and install unchanged, using a throwaway `XDG_CONFIG_HOME`.

## Options considered

### Option 1: Allow list per key, theme names through the apply tools, unlisted key check in status

Keep only preference keys, let `plasma-apply-colorscheme`, `plasma-apply-cursortheme` and `plasma-changeicons` restore the theme picks that expand into other settings, record every left out key with a `!` line, and have `dot status` flag anything undecided.

**Pros**:
- About 60 keys instead of about 170, and every one of them is a choice you made.
- Theme picks restore the way System Settings does them, including GTK colors and title bars.
- New tweaks surface on their own.

**Cons**:
- Three small special cases in `dot` (the apply table).
- A one time triage of every key in the tracked files (done in this spec).

### Option 2: Allow list per key, including the expanded `[Colors:*]` groups

The mechanism exactly as 0001 built it, with about 110 more color keys listed.

**Pros**:
- No new code path.

**Cons**:
- GTK apps and window title colors may not follow, because nothing triggers the apply step.
- A scheme update upstream leaves your copy stale; the repo holds a frozen copy of a theme file.

### Option 3: Manual upkeep, no status check

Option 1 without the unlisted key check; you add lines when you remember.

**Pros**:
- Less code.

**Cons**:
- The failure is silent: a setting changed months ago is simply missing on the next machine, and you find out only then.

## Decision

**Chosen option**: Option 1: allow list per key, theme names through the apply tools, unlisted key check in `dot status`.

Feature 7 keeps the keys listed below, restores theme picks with KDE's apply tools, marks every other key with a `!` line, and teaches `dot status` to flag undecided keys.

## Rationale

The repo is public and the allow list is the only thing between a mixed rc file and a commit, so the list stays a list of names, and every left out key is written down too. That second half is what makes the unlisted key check work: without `!` lines `dot status` would nag about window sizes forever and you would learn to ignore it.

Theme picks are different from other keys because KDE derives many other keys from them. The apply tools are the supported way to do that, they ship with Plasma (all three are on this machine), and they keep working when MacTahoe updates its scheme. Only three picks need a tool: the color scheme expands into about 110 color keys, and the icon and cursor tools also update GTK. The plasma theme and the Kvantum theme are single keys that a plain write restores just as well, so they stay plain (cross check, 2026-10-11). Skipping a missing theme instead of failing keeps install usable before feature 8 delivers the theme files.

Panels stay with feature 8 because `plasma-org.kde.plasma.desktop-appletsrc` is keyed by numeric containment IDs that a fresh machine does not share; the theme repo's layout script (0001, AC-13) is the right tool for that.

## Feature design

**Kept keys** (each one line in `kde/allow.list`, AC-1):

| rcfile | Group | Keys |
|---|---|---|
| `kglobalshortcutsrc` | `kwin` | `Window Maximize`, `Window Quick Tile Top` (already there) |
| `kglobalshortcutsrc` | `plasmashell` | `previous activity` |
| `kglobalshortcutsrc` | `services/org.kde.spectacle.desktop` | `CurrentMonitorScreenShot`, `OpenWithoutScreenshot` |
| `kdeglobals` | `General` | `BrowserApplication`, `TerminalApplication`, `TerminalService`, `UseSystemBell`, `font`, `menuFont`, `smallestReadableFont`, `toolBarFont`, `ColorScheme` (apply) |
| `kdeglobals` | `Icons` | `Theme` (apply) |
| `kdeglobals` | `KDE` | `AnimationDurationFactor`, `widgetStyle` |
| `kdeglobals` | `WM` | `activeFont` |
| `kdeglobals` | `KFileDialog Settings` | `Allow Expansion`, `Automatically select filename extension`, `Breadcrumb Navigation`, `Decoration position`, `Show Full Path`, `Show Inline Previews`, `Show Preview`, `Show Speedbar`, `Show hidden files`, `Sort by`, `Sort directories first`, `Sort hidden files last`, `Sort reversed`, `Speedbar Width`, `View Style` |
| `kwinrc` | `Desktops` | `Number`, `Rows` |
| `kwinrc` | `EdgeBarrier` | `EdgeBarrier` |
| `kwinrc` | `Effect-overview` | `BorderActivate` |
| `kwinrc` | `Plugins` | `shakecursorEnabled` |
| `kwinrc` | `TabBox` | `HighlightWindows` |
| `kwinrc` | `org.kde.kdecoration2` | `ButtonsOnLeft`, `ButtonsOnRight`, `library`, `theme` |
| `kcminputrc` | `Mouse` | `cursorTheme` (apply) |
| `kcminputrc` | `Libinput/1133/16531/Logitech PRO X` | `NaturalScroll`, `PointerAcceleration`, `PointerAccelerationProfile`, `ScrollMethod` |
| `kcminputrc` | `Libinput/2362/12310/ASCP1200:00 093A:3016 Mouse` | `PointerAccelerationProfile` |
| `kcminputrc` | `Libinput/2362/12310/ASCP1200:00 093A:3016 Touchpad` | `MiddleButtonEmulation`, `NaturalScroll`, `ScrollFactor` |
| `powerdevilrc` | `AC/Keyboard` | `KeyboardBrightness`, `UseProfileSpecificKeyboardBrightness` |
| `powerdevilrc` | `AC/SuspendAndShutdown` | `AutoSuspendIdleTimeoutSec` |
| `powerdevilrc` | `Battery/SuspendAndShutdown` | `AutoSuspendIdleTimeoutSec`, `PowerButtonAction` |
| `powerdevilrc` | `General` | `pausePlayersOnSuspend` |
| `plasmarc` | `PlasmaViews` | `PanelHoverDelay` |
| `plasmarc` | `Theme` | `name` |
| `ksmserverrc` | `General` | `loginMode` |
| `plasmanotifyrc` | `Notifications` | `PopupTimeout` |
| `klipperrc` | `General` | `KeepClipboardContents`, `MaxClipItems`, `SelectionTextOnly` |
| `kiorc` | `Confirmations` | `ConfirmEmptyTrash` |
| `dolphinrc` | `DetailsMode` | `PreviewSize` |
| `dolphinrc` | `IconsMode` | `PreviewSize` |
| `dolphinrc` | `KFileDialog Settings` | `Places Icons Auto-resize`, `Places Icons Static Size` |
| `dolphinrc` | `MainWindow` | `MenuBar` |
| `spectaclerc` | `Annotations` | `annotationToolType`, `freehandStrokeColor`, `freehandStrokeWidth`, `rectangleFillColor`, `rectangleStrokeColor` |
| `Kvantum/kvantum.kvconfig` | `General` | `theme` |

The `Libinput` groups name hardware models, not personal devices; your Done when ("no device names") is read as no personal device names such as a Bluetooth name you chose (your call, 2026-10-11).

**Left out keys** (`!` lines, AC-2), each with the reason as a `#` comment above it in `allow.list`:

| Line | Why |
|---|---|
| One `!kdeglobals <group>` line per color group present (`Colors:Button`, `Colors:Complementary`, `Colors:Header`, `Colors:Header/Inactive`, `Colors:Selection`, `Colors:Tooltip`, `Colors:View`, `Colors:Window`, `ColorEffects:Disabled`, `ColorEffects:Inactive`) | expanded from the color scheme by the apply tool |
| `!kdeglobals General ColorSchemeHash` | written by the apply tool |
| `!kdeglobals KDE LookAndFeelPackage`, `!kdeglobals KDE contrast`, `!kdeglobals KDE frameContrast` | stale Global Theme name; contrast comes from the scheme |
| `!kdeglobals WM activeBackground` and the other five `WM` color keys (`activeBlend`, `activeForeground`, `inactiveBackground`, `inactiveBlend`, `inactiveForeground`) | expanded from the scheme |
| `!kdeglobals "KFileDialog Settings" "Recent Files"`, `!kdeglobals "KFileDialog Settings" "Recent URLs"` | paths (your rule: no path, URL or recent list) |
| `!kwinrc Desktops Id_1`, `!kwinrc Tiling`, `!kwinrc Windows_HDR`, `!kwinrc Xwayland` | this screen and its UUIDs, not a preference |
| `!plasmarc Theme-plasma-themeexplorer`, `!plasmarc Wallpapers` | tool state, wallpaper paths (feature 8) |
| `!ksmserverrc "LegacySession: saved at previous logout"`, `!ksmserverrc "Session: saved at previous logout"` | session state |
| `!plasmanotifyrc Applications`, `!plasmanotifyrc DoNotDisturb` | seen apps, a past Do Not Disturb time |
| `!klipperrc General Version` | written by Klipper |
| `!dolphinrc ExtractDialog`, `!dolphinrc General` | window sizes, version stamps |
| `!spectaclerc General ocrLanguages`, `!spectaclerc ImageSave`, `!spectaclerc VideoSave`, `!spectaclerc ViewerWindow` | save paths and window sizes |

Files not tracked at all (no line, so the unlisted check does not read them): `plasmashellrc` and `plasma-org.kde.plasma.desktop-appletsrc` (panels, feature 8), `kwinoutputconfig.json` (monitors), `kwinrulesrc` (empty), the GTK files `gtkrc`, `gtkrc-2.0`, `gtk-3.0/`, `gtk-4.0/` (KDE regenerates them), `kdedefaults/`, `ktimezonedrc`, `plasma-localerc`, every app rc not listed above (spec 0002: app state stays out).

**Theme apply** (AC-3, AC-4):

| What | Key | Tool run with the repo value | Installed check |
|---|---|---|---|
| colorscheme | `kdeglobals General ColorScheme` | `plasma-apply-colorscheme <v>` | `plasma-apply-colorscheme --list-schemes` has a line equal to `<v>` after removing the leading ` * ` and a trailing `(current ...)` note |
| cursortheme | `kcminputrc Mouse cursorTheme` | `plasma-apply-cursortheme <v>` | `plasma-apply-cursortheme --list-themes`, same exact match rule |
| icons | `kdeglobals Icons Theme` | `/usr/lib/plasma-changeicons <v>` (the Arch path; the desktop profile is Arch only) | `~/.local/share/icons/<v>` or `/usr/share/icons/<v>` exists |

A tool runs only when the repo value differs from the live value, the same rule as plain keys, and after every plain key is written. The plasma theme (`plasmarc Theme name`) and the Kvantum theme (`Kvantum/kvantum.kvconfig General theme`) are plain keys: each is the only setting its pick changes, and Plasma or Kvantum falls back to its default until the theme files exist. The Aurorae decoration (`kwinrc org.kde.kdecoration2 theme`) is a plain key too: KWin reads it at log in; when neither `~/.local/share/aurorae/themes/<name without __aurorae__svg__>` nor `/usr/share/aurorae/themes/<same>` exists, install prints the same skipped warning and does not write `library` or `theme`.

**Value sourcing**:

| Action | Value | Source |
|---|---|---|
| install, plain key | the value written | `kde/<rcfile>` in the repo, read with `kreadconfig6` (0001) |
| install, apply key | theme name passed to the tool | the same repo file and key (table above) |
| install, apply key | whether the theme is installed | the tool's own list, or the folder check in the table |
| status, unlisted check | which rc files to scan | rc files named by non `!` lines in `allow.list` |
| status, unlisted check | the keys present in a live file | the live file under `$XDG_CONFIG_HOME` (default `~/.config`), groups `[A][B]` read as `A/B` |
| status, shortcut rule | custom and default shortcut | first and second comma separated fields of the `kglobalshortcutsrc` value |
| AC-8 check | violation patterns | the list in AC-8 (from your rule, 2026-10-11) |

**Key invariants**:
- No key reaches `kde/` unless a non `!` line names it (0001 AC-8, unchanged).
- A `!` line never causes a read or a write.
- Install never applies a Global Theme.

**Security model**: unchanged from 0001; KDE is safe by construction. The unlisted check prints key names only, never values, so a terminal log or screenshot of `dot status` leaks nothing.

**Critical test scenarios**:
- Throwaway user, full restore (AC-9 checklist): MacTahoeDark colors in Dolphin and in a GTK app, MacTahoe plasma theme, Papirus-Dark-Real icons, WhiteSur cursor, Kvantum style on a Qt app, window buttons on the left with MacTahoe title bars, Inter fonts, Meta+Up maximizes, touchpad natural scroll and 0.3 scroll speed, suspend after 5 minutes on battery, clipboard keeps one item, Dolphin without a menu bar, empty session at log in. Verifies **AC-1**, **AC-3**, **AC-9**.
- Missing theme: in the throwaway user before copying the theme folders, install prints a skipped line per missing theme, still writes the other keys, exits 0, and `dot status` reports the theme keys as differing. Verifies **AC-4**.
- New tweak: change a Dolphin setting not in the list, `dot status` names it and exits non zero; add a `!` line, status is clean. Verifies **AC-6**, **AC-7**.
- Privacy sweep over every committed file under `kde/`, count 0. Verifies **AC-8**.
- `tests/dot-status.sh` cases. Verifies **AC-2**, **AC-6**, **AC-10**.

## Build plan

Tracer Bullet: one thread through every new path first (one `!` line, one unlisted key, one apply key), then the full list.

1. `kde_keys` skips `!` lines; a new `kde_ignores` reads them (three forms). Sync handles an rc path with a folder (`Kvantum/kvantum.kvconfig`: create the parent folder in the temp dir and under `kde/`). Satisfies **AC-2**.
2. Unlisted key check in `dot status`: parse each tracked live rc file into `group<TAB>key`, drop allow and `!` matches, apply the shortcut rule, print names, count problems. Add the `tests/dot-status.sh` cases with a throwaway `XDG_CONFIG_HOME`. Satisfies **AC-6**, **AC-10**.
3. Apply table in `dot` for the three keys and the Aurorae folder check; plain keys first, tools last; the session guard; install runs the tool or prints the skipped line; dry run prints `would run` or skipped. Thread it with `ColorScheme` first, then the other two. Satisfies **AC-3**, **AC-4**, **AC-5**.
4. Fill `kde/allow.list` with every kept and left out line from the tables (with `#` reasons), run `dot sync`, review the new `kde/` files. Satisfies **AC-1**, **AC-2**.
5. Run `dot status` on this machine until it reports zero unlisted keys; any key not in the tables here is a question for you, not a silent `!`. Satisfies **AC-7**.
6. Privacy sweep script over `kde/` (count printed, must be 0); run it, and add it to `tests/dot-status.sh`. Satisfies **AC-8**.
7. Throwaway user check per the checklist, theme folders copied by hand, user deleted after. Satisfies **AC-9**.

## Consequences

**Positive**:
- A new desktop gets your KDE preferences from one install and a log out.
- Settings you change later are flagged instead of lost.
- Theme picks stay correct when MacTahoe updates its scheme.

**Negative / tradeoffs**:
- `dot status` goes red whenever you tweak KDE until you decide the new key; that is the point, but it is noise during a tuning session.
- Restoring the full look depends on feature 8 (theme files) and feature 10 (Inter font, Kvantum package); until then install prints skipped lines.
- The input groups only apply on hardware with the same models.

**Neutral**:
- `dot` gains a three row apply table and a `!` line parser.
- Your tiling layout (25/50/25) is not restored; it is keyed by screen UUIDs.

## Follow-up

- [ ] Feature 8: the layout script restores panels, dock and wallpaper; feature 8's verify replaces the hand copied theme folders of AC-9.
- [ ] Feature 10: `ttf-inter` (or the package that provides Inter) and `kvantum` on the desktop install list, if not already there.
- [x] Update spec 0001's Follow-up box "Feature 7 decides the exact rc files and keys" to point here.
