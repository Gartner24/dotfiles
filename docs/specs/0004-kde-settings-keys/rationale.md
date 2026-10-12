# 0004. KDE settings: rationale

Decision record for [index.md](index.md): the context, the options weighed, and why.

## Context

Spec 0001 already decided the mechanism: KDE rc files are never linked, `kde/allow.list` names each kept key, `dot sync` reads them with `kreadconfig6`, `dot install` writes them with `kwriteconfig6` and asks you to log out. It left one thing open (its Follow-up): which files and keys. Today the list holds two `kglobalshortcutsrc` keys.

A survey of your live `~/.config` on 2026-10-11 shaped the answer. `kwinrulesrc` is empty and `panel-colorizer/presets` is empty, so there are no window rules or colorizer presets to keep. Only four global shortcuts differ from KDE's defaults. Your look is assembled by hand: `LookAndFeelPackage` still says `org.kde.breezedark.desktop` while the color scheme, plasma theme, icons, cursor, Kvantum and Aurorae are MacTahoe, Papirus and WhiteSur, so applying a Global Theme (a bundle of all those picks) would overwrite your setup with Breeze Dark.

Two traps drive the rest. First, `kdeglobals` holds about 110 `[Colors:*]`, `[ColorEffects:*]` and `[WM]` color keys that KDE expands from the scheme when you pick it; copying `ColorScheme=MacTahoeDark` alone recolors nothing, and copying all 110 keys skips the GTK and window title updates the apply tool does. Second, an allow list only reads what it names, so any setting you tweak after today is lost on the next machine unless something tells you about it.

The repo is public. Several of these files mix preferences with paths and recent lists (Spectacle's last save location, a file dialog's recent URLs). Folder names can name clients, so no key holding a path, URL or recent list may reach the repo.

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

## Rationale

The repo is public and the allow list is the only thing between a mixed rc file and a commit, so the list stays a list of names, and every left out key is written down too. That second half is what makes the unlisted key check work: without `!` lines `dot status` would nag about window sizes forever and you would learn to ignore it.

Theme picks are different from other keys because KDE derives many other keys from them. The apply tools are the supported way to do that, they ship with Plasma (all three are on this machine), and they keep working when MacTahoe updates its scheme. Only three picks need a tool: the color scheme expands into about 110 color keys, and the icon and cursor tools also update GTK. The plasma theme and the Kvantum theme are single keys that a plain write restores just as well, so they stay plain (cross check, 2026-10-11). Skipping a missing theme instead of failing keeps install usable before feature 8 delivers the theme files.

Panels stay with feature 8 because `plasma-org.kde.plasma.desktop-appletsrc` is keyed by numeric containment IDs that a fresh machine does not share; the theme repo's layout script (0001, AC-13) is the right tool for that.


### Update 2026-10-11: shortcuts through D-Bus (AC-11)

The first AC-9 run showed the running KWin putting both `kwin` shortcuts back to their defaults while the session was still open: on Wayland the shortcut service lives inside KWin, keeps every shortcut in memory, and writes that whole set over `kglobalshortcutsrc` whenever it saves. A file write alone can never win while KWin runs, and logging out makes it save its old copy. Options weighed: tell the service over D-Bus (chosen by you), install shortcuts only from a TTY with Plasma logged out (a manual step on every machine), or set the five shortcuts by hand. D-Bus keeps install one command; the cost is a small table of Qt key codes in `dot`. `busctl` is part of systemd, so no new tool. The file is still written so a machine with no session gets the keys at its next login.
