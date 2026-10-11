# Desktop only shell config (spec 0003), sourced late by .zshrc from conf.d.

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

# freeram's last step (freeram lives in .zshrc): Claude sessions open more than a
# day keep all their MCP servers alive, so offer to close them.
_freeram_claude() {
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

export PATH="$HOME/.cargo/bin:$PATH"

# Chrome for lighthouse / chrome-launcher (no system Chrome installed; use Playwright's cached Chromium).
# Globs the newest chromium-* so a Playwright version bump won't break this. ponytail: pin a real path if the glob ever misfires.
# (N) keeps a missing cache silent: without it zsh's nomatch prints "no matches found" in every new shell
# (the 2>/dev/null on the old ls never saw it), and an array avoids ls -d falling back to "." on no match.
_chrome=("$HOME"/.cache/ms-playwright/chromium-*/chrome-linux64/chrome(Nn))
(( $#_chrome )) && export CHROME_PATH="$_chrome[-1]"
unset _chrome

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
