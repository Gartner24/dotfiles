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

# ── NVM ───────────────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# ── mise ──────────────────────────────────────────────────────────────────────
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# ── zoxide ────────────────────────────────────────────────────────────────────
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

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
alias freeram='sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches && echo "RAM cache cleared!"'

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
command -v fastfetch &>/dev/null && fastfetch

echo -e "
\e[33m ╔══════════════════════════════════════════════╗\e[0m
\e[33m ║  \e[32m⚡ Quick Reference                           \e[33m║\e[0m
\e[33m ╠══════════════════════════════════════════════╣\e[0m
\e[33m ║  \e[34m Navigation                                  \e[33m║\e[0m
\e[33m ║  \e[0mz  <name>        → jump to directory          \e[33m║\e[0m
\e[33m ║  \e[0mzi               → fuzzy pick directory       \e[33m║\e[0m
\e[33m ╠══════════════════════════════════════════════╣\e[0m
\e[33m ║  \e[34m Listing                                     \e[33m║\e[0m
\e[33m ║  \e[0mls               → simple list                \e[33m║\e[0m
\e[33m ║  \e[0mll               → detailed list              \e[33m║\e[0m
\e[33m ║  \e[0mla               → list all + hidden          \e[33m║\e[0m
\e[33m ║  \e[0mlt               → tree view (no noise)       \e[33m║\e[0m
\e[33m ║  \e[0mltd              → tree dirs only             \e[33m║\e[0m
\e[33m ╠══════════════════════════════════════════════╣\e[0m
\e[33m ║  \e[34m System                                      \e[33m║\e[0m
\e[33m ║  \e[0mtop              → btop monitor               \e[33m║\e[0m
\e[33m ║  \e[0mcat <file>       → bat with highlighting      \e[33m║\e[0m
\e[33m ║  \e[0mfreeram          → clear RAM cache            \e[33m║\e[0m
\e[33m ╠══════════════════════════════════════════════╣\e[0m
\e[33m ║  \e[34m Dev                                         \e[33m║\e[0m
\e[33m ║  \e[0mnvm use <ver>    → switch Node version        \e[33m║\e[0m
\e[33m ║  \e[0mmise use <tool>  → switch runtime version     \e[33m║\e[0m
\e[33m ║  \e[0mdocker ps        → list containers            \e[33m║\e[0m
\e[33m ╠══════════════════════════════════════════════╣\e[0m
\e[33m ║  \e[34m GUI only                                    \e[33m║\e[0m
\e[33m ║  \e[0mexplorer <path>  → open file manager          \e[33m║\e[0m
\e[33m ║  \e[0mzed              → Zed editor                 \e[33m║\e[0m
\e[33m ║  \e[0mfigma            → Figma Linux                \e[33m║\e[0m
\e[33m ╚══════════════════════════════════════════════╝\e[0m"
