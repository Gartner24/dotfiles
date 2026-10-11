# ── History ───────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_REDUCE_BLANKS
# start a command with a space to keep it out of history (keys, tokens)
setopt HIST_IGNORE_SPACE

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
# no theme: the prompt is Starship, set up further down
ZSH_THEME=""
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)
source $ZSH/oh-my-zsh.sh

# ── PATH ──────────────────────────────────────────────────────────────────────
export PATH="$PATH:$HOME/.local/bin"

# ── Editor ────────────────────────────────────────────────────────────────────
# yazi's default opener runs `${EDITOR:-vi}`, and this box has no vi or vim -
# only nvim. With EDITOR unset, Enter on a text/code file in yazi ran a missing
# binary and looked like nothing happened. nvim is blocking, so yazi hides,
# nvim takes the terminal, and quitting nvim drops you back on the same file.
export EDITOR=nvim
export VISUAL=nvim

# ── yazi ──────────────────────────────────────────────────────────────────────
# `y` instead of `yazi`: on quit, the shell cds to wherever yazi ended up.
# Plain `yazi` still works and leaves the shell where it was.
function y() {
	local tmp cwd
	tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}

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
alias cat='bat'
alias ls='eza'
alias ll='eza --long'
alias la='eza --long --all'
alias lt='eza --icons --tree --level=2 --ignore-glob="node_modules|.git|dist|.next|.cache"'
alias ltd='eza --icons --tree --level=2 --only-dirs --ignore-glob="node_modules|.git|dist|.next|.cache"'
alias top='btop'
alias htop='btop'
alias cd='z'
# freeram: drop caches, empty swap when RAM can hold it, show top memory users and
# offer to close Claude sessions open more than a day. The "available" column is
# your real free memory; dropping caches alone is mostly cosmetic.
unalias freeram 2>/dev/null   # avoid alias/function clash when re-sourcing
freeram() {
  echo "before:"; free -h | grep -E 'Mem|Swap'
  sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null

  # empty swap only if RAM can hold it all plus 1 GB margin, otherwise swapoff itself can freeze
  local avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
  local swapused=$(awk '/SwapTotal/ {t=$2} /SwapFree/ {f=$2} END {print t-f}' /proc/meminfo)
  if (( swapused > 0 && avail > swapused + 1048576 )); then
    echo "moving swap back to RAM..."; sudo swapoff -a && sudo swapon -a
  elif (( swapused > 0 )); then
    echo "swap kept: not enough free RAM to empty it safely"
  fi
  echo "after:"; free -h | grep -E 'Mem|Swap'

  echo "\ntop memory users:"
  ps -eo rss,comm --no-headers | awk '{m[$2]+=$1} END {for (p in m) printf "%7.0f MB  %s\n", m[p]/1024, p}' | sort -rn | head -10

  # Claude sessions open more than a day keep all their MCP servers alive
  local stale=(${(f)"$(ps -eo pid,etimes,comm,args --no-headers | awk '$3=="claude" && $2>86400 && !/--chrome-native-host/ {print $1}')"})
  (( ${#stale} )) || return 0
  echo "\nClaude sessions open more than a day:"
  local p
  for p in $stale; do
    printf "  %-8s %-12s %s\n" $p "$(ps -o etime= -p $p | tr -d ' ')" "$(readlink /proc/$p/cwd)"
  done
  read -q "?Close them? [y/N] " && kill $stale
  echo
}

# clipclear [SECONDS]: wipe the clipboard and Klipper's history, now or after a delay.
# After copying a key from a website: `clipclear 30`, paste it, and it is gone in 30s.
clipclear() {
  ( sleep ${1:-0}; wl-copy --clear; qdbus6 org.kde.klipper /klipper org.kde.klipper.klipper.clearClipboardHistory >/dev/null ) &!
  (( ${1:-0} )) && echo "clipboard clears in ${1}s" || echo "clipboard cleared"
}
# copykey: copy piped text as a secret - Klipper skips it, and it clears after one paste.
#   cat key.txt | copykey
copykey() { wl-copy --sensitive --paste-once }

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

# ── Terminal emulator ─────────────────────────────────────────────────────────
# TERM_EMULATOR = ghostty | alacritty | other, for per-terminal tweaks.
# Inside tmux $TERM is tmux's own, so ask tmux what the attached client runs in.
# Alacritty without its terminfo reports xterm-256color: fall back to its env var.
_term_emulator() {
  local t=$TERM
  [[ -n $TMUX ]] && t=$(tmux display -p '#{client_termname}' 2>/dev/null)
  case $t in
    xterm-ghostty) echo ghostty ;;
    alacritty)     echo alacritty ;;
    *) if   [[ -n $GHOSTTY_RESOURCES_DIR ]]; then echo ghostty
       elif [[ -n $ALACRITTY_WINDOW_ID ]];   then echo alacritty
       else echo other; fi ;;
  esac
}
export TERM_EMULATOR=$(_term_emulator)

# ── Prompt ────────────────────────────────────────────────────────────────────
# Starship replaced Powerlevel10k (feature 14). Without starship installed the shell
# keeps zsh's plain prompt.
# OSC 133 prompt marks: lets tmux jump between prompts (Ctrl+Shift+PgUp/PgDn).
# Starship does not emit them, so the mark goes in front of its prompt.
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
  PROMPT=$'%{\e]133;A\e\\%}'$PROMPT
fi

# ── Startup ───────────────────────────────────────────────────────────────────
# Fresh terminal OR new tmux window/pane, but not a manually nested shell.
# SHLVL breaks under tmux (server bumps it), so gate on the parent process:
# a pane's top shell is spawned by tmux or the terminal; a subshell by another shell.
_is_top_shell() { [[ $(ps -o comm= -p $PPID 2>/dev/null) != (zsh|bash|sh|-zsh|-bash) ]] }
_is_top_shell && command -v fastfetch &>/dev/null && fastfetch

# Shortcuts panel - the tools I keep forgetting.
_shortcuts() {
  print -P "%F{yellow}⚡ shortcuts%f"
  print -P "  %F{cyan}Ctrl+R%f  fuzzy history search      %F{cyan}fd%f NAME   fast file find"
  print -P "  %F{cyan}Ctrl+T%f  insert a file path        %F{cyan}yazi%f      terminal file manager"
  print -P "  %F{cyan}Alt+C%f   fuzzy cd into a dir       %F{cyan}tldr%f CMD  command examples"
  print -P "  %F{cyan}fixall%f  system cleanup            %F{cyan}freeram%f   free ram, close old claude sessions"
  print -P "  %F{cyan}up%f      update everything         %F{cyan}flatpak update%f  flatpaks only"
  print -P "  %F{cyan}nosleep%f screen stays on, no sleep %F{cyan}nosleep off%f  back to normal"
  print -P "  %F{cyan}clipclear%f [s] wipe clipboard        %F{cyan}copykey%f   copy a secret, one paste"
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
# (N) keeps a missing cache silent: without it zsh's nomatch prints "no matches found" in every new shell
# (the 2>/dev/null on the old ls never saw it), and an array avoids ls -d falling back to "." on no match.
_chrome=("$HOME"/.cache/ms-playwright/chromium-*/chrome-linux64/chrome(Nn))
(( $#_chrome )) && export CHROME_PATH="$_chrome[-1]"
unset _chrome

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
    echo ":: [1/6] Removing orphaned packages..."
    # zsh does not word-split unquoted vars: ${(f)...} splits Qtdq output on newlines into an array.
    local -a orphans=(${(f)"$(pacman -Qtdq 2>/dev/null)"})
    if (( ${#orphans} )); then
      sudo pacman -Rns "${orphans[@]}"
    else
      echo "   none"
    fi

    echo ":: [2/6] Cleaning package cache (yay -Sc)..."
    yay -Sc --noconfirm

    echo ":: [3/6] Clearing leftover download scraps..."
    sudo rm -f /var/cache/pacman/pkg/download-* /var/cache/pacman/pkg/*.part 2>/dev/null
    echo "   done"

    echo ":: [4/6] Broken-package check..."
    pacman -Qk 2>/dev/null | grep -iE 'missing|warning' | grep -v '0 missing files' || echo "   none broken"

    echo ":: [5/6] Dead git worktrees..."
    wtclean

    echo ":: [6/6] Trimming system journal to 500M..."
    sudo journalctl --vacuum-size=500M

    echo ":: fixall complete."
  }
fi

# wtclean: remove git worktrees under ~/projects that are dead - clean AND either
# no commits beyond origin's default branch, or HEAD is exactly a merged PR's head.
# Branches are kept, only the folders go. Asks before removing; dirty, open-PR,
# unpushed or closed-unmerged ones are listed and left alone.
wtclean() {
  local repo wt br def ahead prhead
  local -a dead keep
  for repo in ~/projects/*/*(/N); do
    [ -d "$repo/.git" ] || continue
    git -C "$repo" worktree prune
    for wt in ${(f)"$(git -C "$repo" worktree list --porcelain | sed -n 's/^worktree //p' | tail -n +2)"}; do
      if [ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then keep+=("$wt  (uncommitted changes)"); continue; fi
      def=$(git -C "$wt" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
      ahead=$(git -C "$wt" rev-list --count "$def..HEAD" 2>/dev/null)
      if [ "$ahead" = 0 ]; then dead+=("$wt"); continue; fi
      br=$(git -C "$wt" branch --show-current)
      prhead=""
      [ -n "$br" ] && prhead=$(cd "$wt" && gh pr list --head "$br" --state merged --json headRefOid --jq '.[0].headRefOid // ""' 2>/dev/null)
      if [ -n "$prhead" ] && [ "$prhead" = "$(git -C "$wt" rev-parse HEAD)" ]; then dead+=("$wt")
      else keep+=("$wt  ($ahead commits not on $def, no matching merged PR)"); fi
    done
  done
  (( ${#keep} )) && { echo "   kept:"; printf '     %s\n' "${keep[@]}"; }
  if (( ! ${#dead} )); then echo "   no dead worktrees"; return; fi
  echo "   dead:"; printf '     %s\n' "${dead[@]}"
  read -q "?   Remove these ${#dead} worktrees? [y/N] " || { echo; return; }
  echo
  for wt in "${dead[@]}"; do
    git --git-dir="$(git -C "$wt" rev-parse --path-format=absolute --git-common-dir)" worktree remove "$wt" && echo "   removed $wt"
  done
}

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

  # a kernel update deletes the running kernel's modules: new USB/wifi devices fail until reboot
  [[ -d /usr/lib/modules/$(uname -r) ]] || echo ":: kernel updated - reboot soon (new USB/wifi devices may fail until then)"
  echo ":: up complete."
}

# ── Sleep control ─────────────────────────────────────────────────────────────
# nosleep       - screen never blanks, machine never idle-suspends
# nosleep off   - back to KDE's normal timeouts
# nosleep status
#
# Two inhibitors nested, because they cover different things:
#   systemd-inhibit --what=idle:sleep  -> logind, blocks auto-suspend
#   kde-inhibit --power --screenSaver  -> KWin, blocks screen blank + lock screen
# The logind one alone was tried first and the screen still went black - logind
# has no concept of the display. Nesting keeps it to one process to kill;
# killing the outer reaps the whole tree.
#
# Lasts until 'nosleep off', logout, or reboot. Closing the LID still suspends -
# handle-lid-switch is left alone so a bagged laptop cannot cook itself.
# pgrep/pkill use -x (whole-cmdline match) so a shell that merely has this
# string in its argv is not a target.
_NOSLEEP_CMD="systemd-inhibit --what=idle:sleep --who=nosleep --why=long-running-session kde-inhibit --power --screenSaver sleep infinity"
nosleep() {
  case "$1" in
    off|stop)
      pkill -xf "$_NOSLEEP_CMD" \
        && echo "sleep + screen blanking re-enabled" \
        || echo "nosleep was not active"
      ;;
    status)
      pgrep -xf "$_NOSLEEP_CMD" >/dev/null \
        && echo "nosleep ACTIVE - screen stays on, no idle suspend" \
        || echo "normal - KDE timeouts apply"
      ;;
    ""|on|start)
      if pgrep -xf "$_NOSLEEP_CMD" >/dev/null; then
        echo "nosleep already active"
        return
      fi
      command -v kde-inhibit >/dev/null || {
        echo "nosleep: kde-inhibit not found (install plasma-workspace)" >&2
        return 1
      }
      setsid ${=_NOSLEEP_CMD} >/dev/null 2>&1 </dev/null &
      disown
      sleep 0.3
      pgrep -xf "$_NOSLEEP_CMD" >/dev/null \
        && echo "nosleep ACTIVE - 'nosleep off' to undo" \
        || { echo "nosleep failed to start" >&2; return 1 }
      ;;
    *)
      echo "usage: nosleep [on|off|status]" >&2
      return 1
      ;;
  esac
}

# ── claude-fb: Claude Code on Ollama Cloud, for when the Claude usage limit is hit ──
# Uses the normal ~/.claude config (hooks, plugins, MCP, jjstack, sessions); only the provider env differs.
# Needs: ollama installed, `ollama signin` done, ollama service running.
# Resume the capped session with: claude-fb --resume
claude-fb() {
  # fb-safe = Ollama Cloud -> Groq (no training on prompts). fb-any also falls back to Gemini free
  # and Mistral free, which train on / review prompts: never for client code. Set CLAUDE_FB_MODEL=fb-any.
  local m="${CLAUDE_FB_MODEL:-fb-safe}" k
  k=$(sed -n 's/^LITELLM_MASTER_KEY=//p' "$HOME/.config/claude-fb/keys.env")
  if ! curl -s -m 1 http://127.0.0.1:4000/health/liveliness >/dev/null; then
    ( setsid nohup "$HOME/.local/share/claude-fb/start-proxy.sh" >"$HOME/.local/state/claude-fb/litellm.log" 2>&1 & )
    for _ in {1..40}; do curl -s -m 1 http://127.0.0.1:4000/health/liveliness >/dev/null && break; sleep 0.5; done
  fi
  CLAUDE_PROVIDER_LABEL="$m" \
  CLAUDE_CODE_EFFORT_LEVEL="${CLAUDE_FB_EFFORT:-high}" \
  ANTHROPIC_BASE_URL="http://127.0.0.1:4000" \
  ANTHROPIC_AUTH_TOKEN="$k" \
  ANTHROPIC_API_KEY="" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="$m" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="$m" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="$m" \
  CLAUDE_CODE_SUBAGENT_MODEL="$m" \
  command claude --model "$m" "$@"
}

# opencode
export PATH=/home/santiago/.opencode/bin:$PATH
