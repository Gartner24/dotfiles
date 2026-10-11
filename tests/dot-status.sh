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
  out=$("$T/repo/dot" status 2>&1); rc=$?
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

exit $fail
