#!/usr/bin/env bash
# dot status must report a broken link left when a deleted file's whole folder leaves a
# package (spec 0001, AC-14). Runs dot against a throwaway repo and HOME; touches nothing real.
# Run: tests/dot-status.sh
set -uo pipefail

SRC=$(dirname "$(readlink -f "$0")")/..
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home GIT_CONFIG_GLOBAL=$T/gitconfig
git config --global user.name test
git config --global user.email test@example.com
git config --global protocol.file.allow always
git config --global init.defaultBranch main
mkdir -p "$HOME"
fail=0

check() { # name, expected exit, expected line (empty: none)
  local out rc
  out=$("$DOT" status 2>&1); rc=$?
  if [[ $rc != "$2" || ( -n $3 && $out != *"$3"* ) ]]; then
    echo "FAIL $1 (exit $rc)"; echo "$out" | sed 's/^/  /'; fail=1
  else echo "ok   $1"
  fi
}

# a submodule standing in for nvim.lua
git init -q "$T/sub"
mkdir -p "$T/sub/tmp"
echo x >"$T/sub/init.lua"
echo x >"$T/sub/tmp/stray"
git -C "$T/sub" add -A && git -C "$T/sub" commit -qm sub

git init -q "$T/repo"
DOT=$T/repo/dot
cd "$T/repo" || exit 1
cp "$SRC/dot" .
mkdir -p profiles home/app/.config/app/{keep,gone,later}
printf 'app\n' >profiles/server
echo x >home/app/.config/app/keep/f
echo x >home/app/.config/app/gone/f
echo x >home/app/.config/app/later/f
git submodule add -q "$T/sub" home/app/.config/nv
git add -A && git commit -qm init
./dot install server >/dev/null || { echo "FAIL install"; exit 1; }
check "clean install" 0 "all good"

git rm -rq home/app/.config/app/gone && git commit -qm gone
check "folder deleted and committed" 1 "broken link: ~/.config/app/gone/f"

rm -r home/app/.config/app/later
check "folder deleted, not committed" 1 "broken link: ~/.config/app/later/f"

git -C home/app/.config/nv rm -rq tmp && git -C home/app/.config/nv commit -qm drop
check "folder deleted inside a submodule" 1 "broken link: ~/.config/nv/tmp/stray"

# --- KDE keys: ! lines and the unlisted key check (spec 0004, AC-10) ---------------
command -v kreadconfig6 >/dev/null || { echo "skip KDE cases: no kreadconfig6"; exit $fail; }
export XDG_CONFIG_HOME=$HOME/.config
C=$XDG_CONFIG_HOME
FONT='Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular Text'
git init -q "$T/kde"
DOT=$T/kde/dot
cd "$T/kde" || exit 1
cp "$SRC/dot" .
mkdir -p profiles kde "$C"
: >profiles/desktop
cat >kde/allow.list <<'EOF'
testrc General font
testrc General Picked
!testrc General Stale
!testrc Window
kglobalshortcutsrc kwin "Window Maximize"
EOF
cat >"$C/testrc" <<EOF
[General]
font=$FONT
Picked[\$i]=yes
Stale=1

[Window]
Height=5

[Window][Sub]
Width=10
EOF
cat >"$C/kglobalshortcutsrc" <<'EOF'
[kwin]
_k_friendly_name=KWin
Window Maximize=Meta+Up,Meta+PgUp,Maximize Window
Window Minimize=Meta+PgDown,Meta+PgDown,Minimize Window
EOF
git add -A && git commit -qm init
./dot install desktop >/dev/null </dev/null || { echo "FAIL kde install"; exit 1; }
./dot sync >/dev/null 2>&1 </dev/null

if grep -qE 'Stale|Height|Width' kde/testrc; then echo "FAIL sync wrote a ! key"; sed 's/^/  /' kde/testrc; fail=1
else echo "ok   sync never writes a ! key"
fi
check "! key, ! group, nested group, [\$i] key, default shortcut" 0 "all good"

kwriteconfig6 --file testrc --group General --key font -- 'Noto Sans,9'
./dot install desktop >/dev/null </dev/null
got=$(kreadconfig6 --file testrc --group General --key font)
if [[ $got == "$FONT" ]]; then echo "ok   font with commas and spaces round trips"
else echo "FAIL font round trip: $got"; fail=1
fi

sed -i 's/^\[General\]$/[General]\nNew=1/' "$C/testrc"
check "unlisted key flagged" 1 "kde: testrc [General] New is not in allow.list"
echo '!testrc General New' >>kde/allow.list
check "unlisted key quieted by a ! line" 0 "all good"

sed -i 's/^Window Minimize=Meta+PgDown,/Window Minimize=Meta+End,/' "$C/kglobalshortcutsrc"
check "changed shortcut flagged" 1 "kde: kglobalshortcutsrc [kwin] Window Minimize is not in allow.list"
echo '!kglobalshortcutsrc kwin "Window Minimize"' >>kde/allow.list

echo '!testrc General font' >>kde/allow.list
check "allow plus ! overlap reported" 1 "dot: allow.list covers testrc [General] font twice"

# --- theme apply (spec 0004, AC-3, AC-4); dry runs only, a real apply would reach the live session
install_out() { # name, expected line, env...
  local name=$1 want=$2 out; shift 2
  out=$(env "$@" ./dot install desktop -n 2>&1 </dev/null)
  if [[ $? == 0 && $out == *"$want"* ]]; then echo "ok   $name"
  else echo "FAIL $name"; echo "$out" | sed 's/^/  /'; fail=1
  fi
}
cat >>kde/allow.list <<'EOF'
kdeglobals General ColorScheme
kwinrc org.kde.kdecoration2 library
kwinrc org.kde.kdecoration2 theme
EOF
printf '[General]\nColorScheme=Oxygen\n' >kde/kdeglobals
printf '[org.kde.kdecoration2]\nlibrary=org.kde.kwin.aurorae\ntheme=__aurorae__svg__NoSuchDeco\n' >kde/kwinrc
install_out "installed scheme would run" "kde     apply colorscheme Oxygen would run" DISPLAY=:0
install_out "missing decoration skipped" "kde: decoration theme __aurorae__svg__NoSuchDeco is not installed, skipped" DISPLAY=:0
install_out "no session skips apply" "kde: theme apply needs a Plasma session, skipped" -u DISPLAY -u WAYLAND_DISPLAY
kwriteconfig6 --file "$T/kde/kde/kdeglobals" --group General --key ColorScheme -- NoSuchScheme
install_out "missing scheme skipped" "kde: colorscheme theme NoSuchScheme is not installed, skipped" DISPLAY=:0
if env -u DISPLAY -u WAYLAND_DISPLAY ./dot install desktop >/dev/null 2>&1 </dev/null && ! grep -qs kdecoration2 "$C/kwinrc" && ! grep -qs ColorScheme "$C/kdeglobals"; then
  echo "ok   no session: install exits 0, no decoration keys, no plain ColorScheme write"
else echo "FAIL no session: install failed, or wrote decoration keys or a plain ColorScheme"; fail=1
fi

exit $fail
