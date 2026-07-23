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
# Only on a fresh terminal (SHLVL 1), not in splits/subshells.
[[ $SHLVL -eq 1 ]] && command -v fastfetch &>/dev/null && fastfetch

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
