#!/usr/bin/env bash
# Server profile in containers (spec 0003, AC-11): dot install server on every supported
# release, then the shell checks (AC-1, AC-3, AC-4, AC-5, AC-6, AC-7), the startup ratio
# on archlinux (AC-8) and the mise fallback on debian:12 (AC-10).
# The repo is mounted read only and copied inside, so the real repo and HOME stay untouched.
# Needs docker and network (packages, the Oh My Zsh sparse checkout, mise tools).
# Run: tests/server-profile.sh [image...]
set -uo pipefail

IMAGES=(archlinux debian:12 debian:13 ubuntu:22.04 ubuntu:24.04 ubuntu:26.04)

if [[ ${1:-} != --inside ]]; then
  command -v docker >/dev/null && docker info >/dev/null 2>&1 || { echo "docker is not available, nothing tested"; exit 2; }
  SRC=$(dirname "$(readlink -f "$0")")/..
  SRC=$(readlink -f "$SRC")
  (($#)) && IMAGES=("$@")
  fail=0
  for img in "${IMAGES[@]}"; do
    echo "== $img"
    docker run --rm -v "$SRC:/src:ro" -e IMG="$img" "$img" bash /src/tests/server-profile.sh --inside || fail=1
  done
  ((fail)) && echo "FAILED" || echo "all images passed"
  exit $fail
fi

# --- inside the container, as root ------------------------------------------------
fail=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; [[ -n ${2:-} ]] && echo "$2" | sed 's/^/  /'; fail=1; }
zi() { zsh -i -c "$1" </dev/null 2>&1; }   # a new interactive shell

# Packages. ubuntu:22.04 leaves out zoxide, bat and eza on purpose: the AC-4 failure case.
if [[ -f /etc/arch-release ]]; then
  pacman -Syu --noconfirm --needed zsh git stow fzf zoxide bat fd eza btop starship jq \
    zsh-autosuggestions zsh-syntax-highlighting hyperfine >/dev/null || { bad "pacman install"; exit 1; }
else
  export DEBIAN_FRONTEND=noninteractive
  # Ubuntu container images drop /usr/share/doc, where fzf keeps its zsh files; a
  # regular Ubuntu server keeps them, so let them through like there.
  [[ -f /etc/dpkg/dpkg.cfg.d/excludes ]] && echo 'path-include=/usr/share/doc/fzf/*' >/etc/dpkg/dpkg.cfg.d/zz-fzf
  apt-get update -qq >/dev/null
  pk=(zsh git stow fzf fd-find procps ca-certificates zsh-autosuggestions zsh-syntax-highlighting)
  [[ $IMG != ubuntu:22.04 ]] && pk+=(zoxide bat)
  apt-get install -y -qq "${pk[@]}" >/dev/null || { bad "apt install"; exit 1; }
  [[ $IMG != ubuntu:22.04 ]] && { apt-get install -y -qq eza >/dev/null 2>&1 || true; }
  apt-get install -y -qq btop >/dev/null 2>&1 || true
fi

# The repo as committed, plus uncommitted changes from the mounted working tree.
git config --global --add safe.directory '*'
git config --global protocol.file.allow always
git clone -q /src /repo || { bad "clone repo"; exit 1; }
(cd /src && git ls-files -mo --exclude-standard -z | xargs -0 -r cp -p --parents -t /repo 2>/dev/null)
(cd /src && git ls-files -d) | while IFS= read -r f; do rm -f "/repo/$f"; done
# submodules from the mounted checkout, not the network
git -C /repo config -f .gitmodules --get-regexp '\.path$' | while read -r key path; do
  git -C /repo config "${key%.path}.url" "/src/$path"
done

git clone -q --depth 1 --filter=blob:none --sparse https://github.com/ohmyzsh/ohmyzsh ~/.local/share/omz-git &&
  git -C ~/.local/share/omz-git sparse-checkout set --no-cone /lib/git.zsh /plugins/git/ ||
  bad "omz sparse checkout"

# AC-1
out=$(/repo/dot install server 2>&1) && ok "dot install server" || bad "dot install server" "$out"

# AC-7: no link into a desktop package, no system folder copied, only server submodules
desk=$(sed 's/#.*//; s/[[:space:]]//g; /^$/d' /repo/profiles/desktop)
links=$(find ~ -type l -not -path '*/.git/*' -printf '%l\n' 2>/dev/null)
hits=""
for p in $desk; do hits+=$(grep -E "home/$p/" <<<"$links"); done
[[ -z $hits ]] && ok "no link into a desktop package" || bad "links into desktop packages" "$hits"
for p in $desk; do
  [[ -d /repo/system/$p ]] || continue
  out=$(cd "/repo/system/$p" && find . -type f -printf '/%P\n' | while read -r f; do [[ -e $f ]] && echo "$f"; done)
  [[ -z $out ]] && ok "system/$p not copied" || bad "system/$p copied" "$out"
done
srv=$(sed 's/#.*//; s/[[:space:]]//g; /^$/d' /repo/profiles/server)
out=$(git -C /repo submodule status | awk '$1 !~ /^-/ {print $2}' | while read -r s; do
  ok=0; for p in $srv; do [[ $s == "$p" || $s == home/$p/* ]] && ok=1; done; ((ok)) || echo "$s"; done)
[[ -z $out ]] && ok "only server submodules initialized" || bad "desktop submodules initialized" "$out"

# AC-3: no Oh My Zsh, git aliases from the sparse checkout, plugins from the distro
out=$(zi '(( ! $+functions[omz] )) && alias gst && whence -w git_current_branch &&
  (( $+functions[_zsh_autosuggest_start] )) && (( $+functions[_zsh_highlight] )) && echo PASS')
[[ $out == *PASS* ]] && ok "git aliases and plugins without Oh My Zsh" || bad "git aliases or plugins" "$out"

# AC-4: aliases only for tools on PATH, Debian binary names, fzf bindings
out=$(zi 'for c in cd cat ls top; do print -r -- "$c $(whence -w $c)"; done
  print -r -- "fzf $FZF_DEFAULT_COMMAND"; bindkey "^R"; cd /tmp && pwd; ls / >/dev/null && echo LS_OK')
exp() { # tool alias-or-builtin-word
  if command -v "$1" >/dev/null; then [[ $out == *"$2: alias"* ]]; else [[ $out != *"$2: alias"* ]]; fi
}
bat=bat; command -v bat >/dev/null || bat=batcat
fd=fd; command -v fd >/dev/null || fd=fdfind
res=""
exp zoxide "cd cd" || res+=" cd"
exp "$bat" "cat cat" || res+=" cat"
exp eza "ls ls" || res+=" ls"
exp btop "top top" || res+=" top"
[[ $out == *"fzf $fd --type f"* ]] || res+=" fzf-command"
[[ $out == *fzf-history-widget* ]] || res+=" fzf-bindings"
[[ $out == *$'\n/tmp\n'* && $out == *LS_OK* ]] || res+=" cd-ls-work"
[[ -z $res ]] && ok "guarded aliases and Debian names" || bad "aliases:$res" "$out"

# AC-5, AC-6 as root without sudo
out=$(zi 'freeram' ); [[ $out != *"sudo"* ]] && ok "freeram runs without sudo" || bad "freeram called sudo" "$out"
if [[ -f /etc/arch-release ]]; then
  out=$(zi 'up; echo "rc=$?"'); [[ $out == *"no supported package manager"*"rc=1"* ]] && ok "up without yay or apt" || bad "up on arch without yay" "$out"
else
  out=$(zi 'up -y -qq; echo "rc=$?"'); [[ $out == *":: up complete."*"rc=0"* && $out != *sudo* ]] && ok "up with apt as root" || bad "up with apt" "$out"
fi

# AC-8: server startup at most half of the desktop one, same container
if [[ $IMG == archlinux ]]; then
  hyperfine --warmup 3 --runs 20 --export-json /tmp/server.json 'zsh -i -c exit' 2>&1 | tail -3
  git clone -q --depth 1 https://github.com/ohmyzsh/ohmyzsh ~/.oh-my-zsh &&
  for p in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
    git clone -q --depth 1 "https://github.com/zsh-users/$p" ~/.oh-my-zsh/custom/plugins/$p
  done
  stow --no-folding -d /repo/home -t ~ zsh-desktop
  hyperfine --warmup 3 --runs 20 --export-json /tmp/desktop.json 'zsh -i -c exit' 2>&1 | tail -3
  s=$(jq -r '.results[0] | .summary.time_wall_clock.mean // .mean' /tmp/server.json 2>/dev/null) d=$(jq -r '.results[0] | .summary.time_wall_clock.mean // .mean' /tmp/desktop.json 2>/dev/null)
  if [[ $s =~ ^[0-9.e-]+$ && $d =~ ^[0-9.e-]+$ ]]; then
    msg=$(awk -v s="$s" -v d="$d" 'BEGIN {printf "server %.0f ms, desktop %.0f ms, ratio %.2f", s * 1000, d * 1000, s / d}')
    awk -v s="$s" -v d="$d" 'BEGIN {exit !(s / d <= 0.5)}' && ok "startup: $msg" || bad "startup: $msg"
  else
    bad "startup: hyperfine gave no result (server '$s', desktop '$d')"
  fi
  stow -D -d /repo/home -t ~ zsh-desktop
fi

# AC-10: starship, eza and neovim from mise, in a machine local config
if [[ $IMG == debian:12 ]]; then
  apt-get install -y -qq gpg wget >/dev/null
  install -dm 755 /etc/apt/keyrings
  wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor >/etc/apt/keyrings/mise-archive-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main" >/etc/apt/sources.list.d/mise.list
  apt-get update -qq >/dev/null && apt-get install -y -qq mise >/dev/null || bad "mise apt repo"
  mkdir -p ~/.config/mise/conf.d
  printf '[tools]\nstarship = "latest"\neza = "latest"\nneovim = "latest"\n' >~/.config/mise/conf.d/server.toml
  mise install -q >/dev/null 2>&1 || bad "mise install" "$(mise install 2>&1 | tail -5)"
  out=$(zi 'print -r -- "$PROMPT"; whence -w ls; nvim --version | head -1')
  v=$(sed -n 's/^NVIM v\([0-9]*\.[0-9]*\).*/\1/p' <<<"$out")
  res=""
  [[ $out == *starship* ]] || res+=" prompt"
  [[ $out == *"ls: alias"* ]] || res+=" eza"
  [[ -n $v ]] && awk -v v="$v" 'BEGIN {split(v, a, "."); exit !(a[1] > 0 || a[2] >= 10)}' || res+=" nvim"
  [[ -z $res ]] && ok "mise fallback: starship, eza, nvim $v" || bad "mise fallback:$res" "$out"
fi

exit $fail
