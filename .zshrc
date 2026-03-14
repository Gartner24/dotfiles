# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000


setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY


# Optional but useful
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# bat alias
alias cat='bat'

# eza aliases
alias ls='eza'
alias ll='eza --long'
alias la='eza --long --all'
alias lt='eza --icons --tree --level=2 --ignore-glob="node_modules|.git|dist|.next|.cache"'
alias ltd='eza --icons --tree --level=2 --only-dirs --ignore-glob="node_modules|.git|dist|.next|.cache"'

# btop
alias top='btop'
alias htop='btop'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Created by `pipx` on 2025-05-20 04:47:20
export PATH="$PATH:$HOME/.local/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

alias figma="figma-linux --enable-features=UseOzonePlatform --ozone-platform=wayland"

export QSYS_ROOTDIR="/home/santiago/altera_lite/25.1std/quartus/sopc_builder/bin"

# Added by Quartus Prime software
export SALT_LICENSE_FILE="$SALT_LICENSE_FILE;/home/santiago/.altera.quartus/questa_lic.dat"
export PATH=$PATH:~/altera_lite/25.1std/quartus/bin

eval "$(zoxide init zsh)"
alias cd='z'
alias freeram='sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches && echo "RAM cache cleared!"'

fastfetch
echo -e "
\e[33m ╔════════════════════════════════════════╗\e[0m
\e[33m ║  \e[32m⚡ Quick Reference                     \e[33m║\e[0m
\e[33m ╠════════════════════════════════════════╣\e[0m
\e[33m ║  \e[34m Navigation                            \e[33m║\e[0m
\e[33m ║  \e[0mz  <name>   → jump to directory        \e[33m║\e[0m
\e[33m ║  \e[0mzi          → fuzzy pick directory      \e[33m║\e[0m
\e[33m ╠════════════════════════════════════════╣\e[0m
\e[33m ║  \e[34m Listing                               \e[33m║\e[0m
\e[33m ║  \e[0mls          → simple list               \e[33m║\e[0m
\e[33m ║  \e[0mll          → detailed list             \e[33m║\e[0m
\e[33m ║  \e[0mla          → list all + hidden         \e[33m║\e[0m
\e[33m ║  \e[0mlt          → tree view                 \e[33m║\e[0m
\e[33m ║  \e[0mltd         → tree dirs only            \e[33m║\e[0m
\e[33m ╠════════════════════════════════════════╣\e[0m
\e[33m ║  \e[34m System                                \e[33m║\e[0m
\e[33m ║  \e[0mtop         → btop monitor              \e[33m║\e[0m
\e[33m ║  \e[0mcat <file>  → bat with highlighting     \e[33m║\e[0m
\e[33m ║  \e[0mfreeram     → Clears ram cache          \e[33m║\e[0m
\e[33m ╚════════════════════════════════════════╝\e[0m"
