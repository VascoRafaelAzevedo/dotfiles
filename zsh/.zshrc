# ---- POWERLEVEL10K INSTANT PROMPT (must be at top) ----
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ---- OH-MY-ZSH ----
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# ---- BASIC ----
export TERM=xterm-kitty
alias v='nvim'
alias \?\?='gh copilot'
alias \?='gh copilot --model "gpt-5-mini"'
alias mirror='scrcpy --always-on-top'
alias t='tmux'
# ---- PATH (clean, no duplicates) ----
export PATH="$HOME/.local/bin:$HOME/flutter/bin:$HOME/.npm-global/bin:$PATH"

# Android
export ANDROID_HOME="$HOME/Android"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# Spicetify
export PATH="$HOME/.spicetify:$PATH"

# Flatpak (optional, keep if needed)
export XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share"

# ---- CONDA (lazy load) ----
lazy_load_conda() {
  unset -f conda
  source "$HOME/anaconda3/etc/profile.d/conda.sh"
}

conda() {
  lazy_load_conda
  conda "$@"
}

# ---- NVM (lazy load) ----
export NVM_DIR="$HOME/.nvm"

lazy_load_nvm() {
  unset -f node npm npx nvm
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
}

node() { lazy_load_nvm; node "$@"; }
npm()  { lazy_load_nvm; npm "$@"; }
npx()  { lazy_load_nvm; npx "$@"; }
nvm()  { lazy_load_nvm; nvm "$@"; }

# ---- COMPLETION (faster) ----
# (handled by oh-my-zsh)

# ---- POWERLEVEL10K CONFIG ----
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ── Modern tool integrations ──────────────────────────────────
export EDITOR=nvim
export VISUAL=nvim
export PAGER="bat --style=plain"

# eza (modern ls)
if has eza; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lah --icons --group-directories-first --git'
  alias tree='eza --tree --icons'
fi

# bat (modern cat)
has bat && alias cat='bat --style=plain --paging=never'

# zoxide (smarter cd)
has zoxide && eval "$(zoxide init zsh --cmd cd)"

# fzf keybinds & completions
[[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && \
    source /usr/share/doc/fzf/examples/key-bindings.zsh
[[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && \
    source /usr/share/doc/fzf/examples/completion.zsh
