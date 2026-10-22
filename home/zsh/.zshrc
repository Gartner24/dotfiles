# ── History ───────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_REDUCE_BLANKS
# start a command with a space to keep it out of history (keys, tokens)
setopt HIST_IGNORE_SPACE

# ── conf.d, early ─────────────────────────────────────────────────────────────
# Profile packages drop files here (zsh-desktop: Oh My Zsh). A missing folder
# stays silent, (N) is the null glob.
for _f in ~/.config/zsh/conf.d/early/*.zsh(N); do source $_f; done
unset _f

# ── Without Oh My Zsh (servers) ───────────────────────────────────────────────
# The framework is most of the startup time, so servers skip it and load only its
# git aliases (gst, gco, git_current_branch) from a sparse checkout of two paths.
if (( ! $+functions[omz] )); then
  autoload -Uz compinit && compinit
  [ -f ~/.local/share/omz-git/lib/git.zsh ] && source ~/.local/share/omz-git/lib/git.zsh
  [ -f ~/.local/share/omz-git/plugins/git/git.plugin.zsh ] && source ~/.local/share/omz-git/plugins/git/git.plugin.zsh
fi

# ── PATH ──────────────────────────────────────────────────────────────────────
export PATH="$PATH:$HOME/.local/bin"

# ── Editor ────────────────────────────────────────────────────────────────────
# yazi's default opener runs `${EDITOR:-vi}`, and this box has no vi or vim -
# only nvim. With EDITOR unset, Enter on a text/code file in yazi ran a missing
# binary and looked like nothing happened. nvim is blocking, so yazi hides,
# nvim takes the terminal, and quitting nvim drops you back on the same file.
export EDITOR=nvim
export VISUAL=nvim

# ── Telemetry opt-out ─────────────────────────────────────────────────────────
# DO_NOT_TRACK is a convention (consoledonottrack.com), honoured by a growing
# number of CLI tools - not a guarantee. The rest are tool-specific and only
# listed because that tool is actually installed here:
#   astro  - 12 projects   next - 1 project   sam - aws-sam-cli via pipx
# GUI apps (Discord, Zoom, Spotify, Telegram) ignore all of these.
# Left at 0 on purpose: 1 switched off Claude remote control and other app features.
export DO_NOT_TRACK=0
export ASTRO_TELEMETRY_DISABLED=1
export NEXT_TELEMETRY_DISABLED=1
export SAM_CLI_TELEMETRY=0

# ── mise (node, go, just, rust) ───────────────────────────────────────────────
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# ── Aliases — always ──────────────────────────────────────────────────────────
# Each alias only when its tool is on PATH: an unconditional `alias cd='z'` gave a
# box without zoxide a broken cd. Debian and Ubuntu ship bat as batcat and fd as fdfind.
if (( $+commands[bat] )); then _bat=bat; elif (( $+commands[batcat] )); then _bat=batcat; fi
if (( $+commands[fd] )); then _fd=fd; elif (( $+commands[fdfind] )); then _fd=fdfind; fi
[ -n "$_bat" ] && alias cat=$_bat
if (( $+commands[eza] )); then
  alias ls='eza'
  alias ll='eza --long'
  alias la='eza --long --all'
  alias lt='eza --icons --tree --level=2 --ignore-glob="node_modules|.git|dist|.next|.cache"'
  alias ltd='eza --icons --tree --level=2 --only-dirs --ignore-glob="node_modules|.git|dist|.next|.cache"'
fi
if (( $+commands[btop] )); then
  alias top='btop'
  alias htop='btop'
fi
# cd='z' is set with zoxide below, not here
# freeram: drop caches, empty swap when RAM can hold it, show top memory users.
# The "available" column is your real free memory; dropping caches alone is mostly
# cosmetic. On the desktop, _freeram_claude (desktop.zsh) also offers to close old
# Claude sessions. sudo only when not root: a fresh server may have no sudo at all.
unalias freeram 2>/dev/null   # avoid alias/function clash when re-sourcing
freeram() {
  local -a sudo; (( EUID )) && sudo=(sudo)
  echo "before:"; free -h | grep -E 'Mem|Swap'
  $sudo sync && echo 3 | $sudo tee /proc/sys/vm/drop_caches >/dev/null

  # empty swap only if RAM can hold it all plus 1 GB margin, otherwise swapoff itself can freeze
  local avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
  local swapused=$(awk '/SwapTotal/ {t=$2} /SwapFree/ {f=$2} END {print t-f}' /proc/meminfo)
  if (( swapused > 0 && avail > swapused + 1048576 )); then
    echo "moving swap back to RAM..."; $sudo swapoff -a && $sudo swapon -a
  elif (( swapused > 0 )); then
    echo "swap kept: not enough free RAM to empty it safely"
  fi
  echo "after:"; free -h | grep -E 'Mem|Swap'

  echo "\ntop memory users:"
  ps -eo rss,comm --no-headers | awk '{m[$2]+=$1} END {for (p in m) printf "%7.0f MB  %s\n", m[p]/1024, p}' | sort -rn | head -10

  (( $+functions[_freeram_claude] )) && _freeram_claude
  return 0
}

# up: update everything. Arch: yay only knows pacman + AUR - it is blind to
# flatpaks, which live in their own repos. Discover used to surface both; it was
# removed 2026-08-07, so this covers the gap.
# No `&&` between the two: answering "n" to yay's confirm exits non-zero, and
# that must not skip the flatpak half.
# Debian/Ubuntu servers: apt, then mise, which holds the tools apt lacks or has too old.
up() {
  local -a sudo; (( EUID )) && sudo=(sudo)
  if (( $+commands[yay] )); then
    echo ":: [1/2] pacman + AUR (yay -Syu)..."
    yay -Syu "$@"

    if command -v flatpak &>/dev/null; then
      echo ":: [2/2] flatpak..."
      flatpak update
    else
      echo ":: [2/2] flatpak not installed - skipped"
    fi

    # a kernel update deletes the running kernel's modules: new USB/wifi devices fail until reboot
    [[ -d /usr/lib/modules/$(uname -r) ]] || echo ":: kernel updated - reboot soon (new USB/wifi devices may fail until then)"
  elif (( $+commands[apt-get] )); then
    echo ":: [1/2] apt (apt-get update, upgrade)..."
    $sudo apt-get update && $sudo apt-get upgrade "$@"

    if (( $+commands[mise] )); then
      echo ":: [2/2] mise upgrade..."
      mise upgrade
    else
      echo ":: [2/2] mise not installed - skipped"
    fi

    [ -f /var/run/reboot-required ] && echo ":: reboot required (/var/run/reboot-required)"
  else
    echo "up: no supported package manager found (yay or apt-get)" >&2
    return 1
  fi
  echo ":: up complete."
}

# ── Prompt ────────────────────────────────────────────────────────────────────
# Starship replaced Powerlevel10k (feature 14). Without starship installed the shell
# keeps zsh's plain prompt.
# OSC 133 prompt marks: lets tmux jump between prompts (Ctrl+Shift+PgUp/PgDn).
# Starship does not emit them, so the mark goes in front of its prompt.
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
  PROMPT=$'%{\e]133;A\e\\%}'$PROMPT
fi

# ── zoxide ────────────────────────────────────────────────────────────────────
export _ZO_DOCTOR=0
# The alias comes after init on purpose: old zoxide (0.4, Debian 12, Ubuntu 22.04)
# calls plain `cd` inside `z`, and an alias defined first expanded into it: endless recursion.
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias cd='z'
fi

# ── fzf (fuzzy finder) ────────────────────────────────────────────────────────
# Ctrl+R fuzzy history, Ctrl+T file picker, Alt+C fuzzy cd. Backed by fd when present.
if command -v fzf &>/dev/null; then
  if [ -n "$_fd" ]; then
    export FZF_DEFAULT_COMMAND="$_fd --type f --hidden --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="$_fd --type d --hidden --exclude .git"
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
  # Arch path, else the Debian/Ubuntu one
  _fzf=/usr/share/fzf; [ -d $_fzf ] || _fzf=/usr/share/doc/fzf/examples
  [ -f $_fzf/key-bindings.zsh ] && source $_fzf/key-bindings.zsh
  [ -f $_fzf/completion.zsh ]   && source $_fzf/completion.zsh
  unset _fzf
fi
unset _bat _fd

# ── conf.d ───────────────────────────────────────────────────────────────────
# Profile packages drop the rest here (zsh-desktop: desktop.zsh). Profile choice
# lives in the profile lists, so this file never checks which machine it is on.
for _f in ~/.config/zsh/conf.d/*.zsh(N); do source $_f; done
unset _f

# ── Plugins without Oh My Zsh (servers) ───────────────────────────────────────
# From the distro packages, Arch path first, then Debian/Ubuntu. Last on purpose:
# syntax highlighting has to wrap every widget defined before it.
if (( ! $+functions[omz] )); then
  for _p in zsh-autosuggestions zsh-syntax-highlighting; do
    for _f in /usr/share/zsh/plugins/$_p/$_p.zsh /usr/share/$_p/$_p.zsh; do
      [ -f $_f ] && { source $_f; break; }
    done
  done
  unset _p _f
fi
