# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'


# ~/.bashrc
# History settings
HISTFILE=~/.histfile
HISTSIZE=10000
HISTFILESIZE=10000
shopt -s histappend # Append to history, don't overwrite

# Enable vi mode for command line editing
set -o vi

# =========================
# Open files/folders in Nautilus
# =========================
open_func() {
  if [[ $# -eq 0 ]]; then
    nautilus . >/dev/null 2>&1 &
  else
    for target in "$@"; do
      if [[ -e "$target" ]]; then
        if [[ -d "$target" ]]; then
          nautilus "$target" >/dev/null 2>&1 &
        else
          nautilus --select "$target" >/dev/null 2>&1 &
        fi
      else
        echo "open: '$target' does not exist"
      fi
    done
  fi
}

alias open='open_func'

# =========================
# Full-screen file finder
# Left 40% = file list
# Right 60% = bat preview
# =========================
fzf_files_nvim() {
  local selection

  selection=$(
    find . -type f 2>/dev/null | \
      fzf --multi \
          --height=100% \
          --layout=reverse \
          --border \
          --preview 'bat --color=always --style=numbers --line-range=:500 {}' \
          --preview-window=right:60%:wrap
  ) || return

  [[ -z "$selection" ]] && return

  printf '%s\n' "$selection" | xargs -r nvim -p

  READLINE_LINE=""
  READLINE_POINT=0
}

# =========================
# History search with confirm
# =========================
fzf_history_confirm() {
  local selected clean_cmd confirm

  selected=$(
    history | \
      fzf --tac \
          --no-sort \
          --reverse \
          --height=100% \
          --border \
          --preview 'echo {}' \
          --preview-window=down:25%:wrap
  ) || {
    READLINE_LINE=""
    READLINE_POINT=0
    return
  }

  [[ -z "$selected" ]] && {
    READLINE_LINE=""
    READLINE_POINT=0
    return
  }

  clean_cmd=$(printf '%s\n' "$selected" | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//')

  printf "Execute this command? (y/n): "
  read -r -n 1 confirm
  echo

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    READLINE_LINE=""
    READLINE_POINT=0
    eval "$clean_cmd"
  else
    echo "Cancelled."
    READLINE_LINE=""
    READLINE_POINT=0
  fi
}

# =========================
# Bash keybinds
# =========================

# Alt + Space → file search
bind -x '"\e ":fzf_files_nvim'

# Alt + h → history search
bind -x '"\eh":fzf_history_confirm'

# Alt + / → bash cheatsheet
bash_cheatsheet() {
  cat ~/.config/bash/cheatsheet | fzf --no-sort --reverse --prompt='Search: ' --header='  Bash Keybindings & Aliases' --color='header:blue,prompt:blue'
  READLINE_LINE=""
  READLINE_POINT=0
}
bind -x '"\e/":bash_cheatsheet'
