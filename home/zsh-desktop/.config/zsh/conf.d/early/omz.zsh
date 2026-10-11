# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
# Desktop only (spec 0003). Servers skip the framework: .zshrc loads the git
# aliases and the two plugins on its own when omz is absent.
export ZSH="$HOME/.oh-my-zsh"
# no theme: the prompt is Starship, set up in .zshrc
ZSH_THEME=""
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)
source $ZSH/oh-my-zsh.sh
