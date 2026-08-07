# Enable Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── History ───────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_REDUCE_BLANKS

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)
source $ZSH/oh-my-zsh.sh

# ── PATH ──────────────────────────────────────────────────────────────────────
export PATH="$PATH:$HOME/.local/bin"

# ── Telemetry opt-out ─────────────────────────────────────────────────────────
# DO_NOT_TRACK is a convention (consoledonottrack.com), honoured by a growing
# number of CLI tools - not a guarantee. The rest are tool-specific and only
# listed because that tool is actually installed here:
#   astro  - 12 projects   next - 1 project   sam - aws-sam-cli via pipx
# GUI apps (Discord, Zoom, Spotify, Telegram) ignore all of these.
export DO_NOT_TRACK=1
export ASTRO_TELEMETRY_DISABLED=1
export NEXT_TELEMETRY_DISABLED=1
export SAM_CLI_TELEMETRY=0

# ── mise (node, go, just, rust) ───────────────────────────────────────────────
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# ── Aliases — always ──────────────────────────────────────────────────────────
alias cat='bat'
alias ls='eza'
alias ll='eza --long'
alias la='eza --long --all'
alias lt='eza --icons --tree --level=2 --ignore-glob="node_modules|.git|dist|.next|.cache"'
alias ltd='eza --icons --tree --level=2 --only-dirs --ignore-glob="node_modules|.git|dist|.next|.cache"'
alias top='btop'
alias htop='btop'
alias cd='z'
# freeram: sync + drop caches, showing before/after. Note: Linux uses free RAM as
# cache on purpose and reclaims it automatically - the "available" column is your
# real free memory. This is mostly cosmetic; useful only for benchmarking cold reads.
unalias freeram 2>/dev/null   # avoid alias/function clash when re-sourcing
freeram() {
  echo "before:"; free -h | grep -E 'Mem|Swap'
  sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
  echo "after:";  free -h | grep -E 'Mem|Swap'
}

# ── Aliases — GUI only ────────────────────────────────────────────────────────
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
  alias explorer='xdg-open'
  alias figma='figma-linux --enable-features=UseOzonePlatform --ozone-platform=wayland'
  alias zed='zeditor'
fi

# ── Arch-only ─────────────────────────────────────────────────────────────────
if [ -f /etc/arch-release ]; then
  export QSYS_ROOTDIR="/home/santiago/altera_lite/25.1std/quartus/sopc_builder/bin"
  export SALT_LICENSE_FILE="$SALT_LICENSE_FILE;/home/santiago/.altera.quartus/questa_lic.dat"
  export PATH=$PATH:~/altera_lite/25.1std/quartus/bin
fi

# ── p10k ──────────────────────────────────────────────────────────────────────
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ── Startup ───────────────────────────────────────────────────────────────────
# Fresh terminal OR new tmux window/pane, but not a manually nested shell.
# SHLVL breaks under tmux (server bumps it), so gate on the parent process:
# a pane's top shell is spawned by tmux/alacritty; a subshell by another shell.
_is_top_shell() { [[ $(ps -o comm= -p $PPID 2>/dev/null) != (zsh|bash|sh|-zsh|-bash) ]] }
_is_top_shell && command -v fastfetch &>/dev/null && fastfetch

# Shortcuts panel - the tools I keep forgetting.
_shortcuts() {
  print -P "%F{yellow}⚡ shortcuts%f"
  print -P "  %F{cyan}Ctrl+R%f  fuzzy history search      %F{cyan}fd%f NAME   fast file find"
  print -P "  %F{cyan}Ctrl+T%f  insert a file path        %F{cyan}yazi%f      terminal file manager"
  print -P "  %F{cyan}Alt+C%f   fuzzy cd into a dir       %F{cyan}tldr%f CMD  command examples"
  print -P "  %F{cyan}fixall%f  system cleanup            %F{cyan}freeram%f   ram usage before/after"
  print -P "  %F{cyan}up%f      update everything         %F{cyan}flatpak update%f  flatpaks only"
}
_is_top_shell && _shortcuts

# Random tldr tip on a fresh terminal - learn one command per session.
_tldr_tip() {
  command -v tldr &>/dev/null || return
  local pages pick
  pages=("${(@f)$(tldr --list 2>/dev/null)}")
  (( ${#pages} )) || return
  pick=${pages[RANDOM % ${#pages} + 1]}
  print -P "%F{yellow}💡 tip - tldr $pick%f"
  tldr "$pick" 2>/dev/null
}
_is_top_shell && _tldr_tip

# bun completions
[ -s "/home/santiago/.bun/_bun" ] && source "/home/santiago/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

alias claude-mem='/home/santiago/.bun/bin/bun "/home/santiago/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

# ── zoxide ────────────────────────────────────────────────────────────────────
export _ZO_DOCTOR=0
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
export PATH="$HOME/.cargo/bin:$PATH"

# Chrome for lighthouse / chrome-launcher (no system Chrome installed; use Playwright's cached Chromium).
# Globs the newest chromium-* so a Playwright version bump won't break this. ponytail: pin a real path if the glob ever misfires.
export CHROME_PATH="$(ls -d "$HOME"/.cache/ms-playwright/chromium-*/chrome-linux64/chrome 2>/dev/null | sort -V | tail -1)"

# ── fzf (fuzzy finder) ────────────────────────────────────────────────────────
# Ctrl+R fuzzy history, Ctrl+T file picker, Alt+C fuzzy cd. Backed by fd when present.
if command -v fzf &>/dev/null; then
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
  [ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
  [ -f /usr/share/fzf/completion.zsh ]   && source /usr/share/fzf/completion.zsh
fi

# ── System maintenance ────────────────────────────────────────────────────────
# fixall: one-shot cleanup - prune orphans, clean caches, report broken packages.
# Run `yay -Syu` yourself first; this handles the tidy-up afterward. Safe and
# repeatable. Does NOT remove apps or big one-off packages (cuda, unused GUIs);
# those stay manual decisions.
if [ -f /etc/arch-release ]; then
  fixall() {
    echo ":: [1/4] Removing orphaned packages..."
    # zsh does not word-split unquoted vars: ${(f)...} splits Qtdq output on newlines into an array.
    local -a orphans=(${(f)"$(pacman -Qtdq 2>/dev/null)"})
    if (( ${#orphans} )); then
      sudo pacman -Rns "${orphans[@]}"
    else
      echo "   none"
    fi

    echo ":: [2/4] Cleaning package cache (yay -Sc)..."
    yay -Sc --noconfirm

    echo ":: [3/4] Clearing leftover download scraps..."
    sudo rm -f /var/cache/pacman/pkg/download-* /var/cache/pacman/pkg/*.part 2>/dev/null
    echo "   done"

    echo ":: [4/4] Broken-package check..."
    pacman -Qk 2>/dev/null | grep -iE 'missing|warning' | grep -v '0 missing files' || echo "   none broken"

    echo ":: fixall complete."
  }
fi

# up: update both package systems. yay only knows pacman + AUR - it is blind to
# flatpaks, which live in their own repos. Discover used to surface both; it was
# removed 2026-08-07, so this covers the gap.
# No `&&` between the two: answering "n" to yay's confirm exits non-zero, and
# that must not skip the flatpak half.
up() {
  echo ":: [1/2] pacman + AUR (yay -Syu)..."
  yay -Syu "$@"

  if command -v flatpak &>/dev/null; then
    echo ":: [2/2] flatpak..."
    flatpak update
  else
    echo ":: [2/2] flatpak not installed - skipped"
  fi

  echo ":: up complete."
}
