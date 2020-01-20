################################################################################
# Basics
################################################################################

bindkey -v
setopt auto_cd beep extended_glob no_match
unsetopt notify
typeset -U path
typeset -U fpath

################################################################################
# History
################################################################################

HISTFILE=~/.zsh/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt hist_verify
setopt append_history inc_append_history share_history extended_history
setopt hist_ignore_dups hist_expire_dups_first

################################################################################
# Prompt
################################################################################

export PS1='%F{242}(%*)%f %F{47}%#%f %F{242}%n %M%f %~ %F{47}%#%f '

################################################################################
# Colors
################################################################################

# ls (BSD)
export CLICOLOR=1 # enable ls colors (macOS)
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx # pastel colors for ls output

# ls (GNU)
# TODO: LS_COLORS and ls alias

# grep
# GREP_OPTIONS is deprecated, so use an alias instead.
alias grep='grep --color=auto'

################################################################################
# Completion
################################################################################

# Completion System Basics (lines generated by compinstall)
zstyle ':completion:*' auto-description '%d'
zstyle ':completion:*' completer _expand _complete _ignored
zstyle ':completion:*' completions 1
zstyle ':completion:*' expand prefix suffix
zstyle ':completion:*' format '%d:'
zstyle ':completion:*' glob 1
zstyle ':completion:*' group-name ''
zstyle ':completion:*' ignore-parents parent pwd
zstyle ':completion:*' insert-unambiguous false
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-suffixes true
zstyle ':completion:*' matcher-list ''
zstyle ':completion:*' menu select=1
zstyle ':completion:*' original true
zstyle ':completion:*' preserve-prefix '//[^/]##/'
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s (%l)'
zstyle ':completion:*' substitute 1
zstyle ':completion:*' verbose true
zstyle :compinstall filename '/Users/paul/.zshrc'
autoload -Uz compinit
compinit

################################################################################
# Git
################################################################################

# convenience shortcut for git log with preferred format
# also passes args through to underlying git-log commands
# example usage:
#   $ gl -n20
gl() {
  paste -d' ' <(git log --color --pretty=format:'%ai' "$@") <(git log --color --oneline --decorate "$@")
}

# "sync up the git repo with upstream"
#
# Switch to the default branch for the repo, and get up to date.
#
# This takes one optional arg, which is the name of the default branch.
# The master branch is assumed if no arg is passed in.
gsync() {
  git fetch origin --prune
  # If there are any uncommitted changes, go no further.
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Uncommitted changes in working tree. Aborting..."
    return
  fi
  git checkout "${1:-master}"
  git rebase origin/${1:-master}
}

# "git rebase on top of"
#
# Rebase the current branch on top of the latest version of the default branch.
#
# This takes one optional arg, which is the name of the default branch.
# The master branch is assumed if no arg is passed in.
gro () {
  gsync "${1:-master}"
  git checkout "@{-1}"
  git rebase "${1:-master}"
}

# git prompt, via Homebrew, when available
if hash brew 2>/dev/null; then
  git_promptable="$(brew --prefix)/etc/bash_completion.d/git-prompt.sh"
  if test -f $git_promptable; then
    source $git_promptable
    export GIT_PS1_SHOWDIRTYSTATE=true
    export GIT_PS1_SHOWUNTRACKEDFILES=true
    # Colors only work when using precmd() (rather than setting PS1 directly).
    export GIT_PS1_SHOWCOLORHINTS=true
    precmd() { __git_ps1 '%F{242}(%*)%f %F{47}%#%f %F{242}%n %M%f %~ ' '%F{47}%#%f ' '(%s) ' }
  fi
fi

# On OS X, preserve the standard Terminal/bash behavior where new tabs
# open in the current working directory.
if [[ $OSTYPE == *darwin* ]]; then
  # inspired by Apple's implementation in /etc/bashrc and http://superuser.com/a/328148
  # Tell the terminal about the working directory at each prompt.
  if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]] && [[ -z "$INSIDE_EMACS" ]]; then
    update_terminal_cwd() {
      # Identify the directory using a "file:" scheme URL, including
      # the host name to disambiguate local vs. remote paths.

      # Percent-encode the pathname.
      local URL_PATH=''
      {
        # Use LANG=C to process text byte-by-byte.
        local i ch hexch LANG=C
        for ((i = 1; i <= ${#PWD}; ++i)); do
          ch="$PWD[i]"
          if [[ "$ch" =~ [/._~A-Za-z0-9-] ]]; then
            URL_PATH+="$ch"
          else
            hexch=$(printf "%02X" "'$ch")
            URL_PATH+="%$hexch"
          fi
        done
      }

      local PWD_URL="file://$HOST$URL_PATH"
      printf '\e]7;%s\a' "$PWD_URL"
    }

    # Register the function to be called whenever the working directory changes.
    autoload add-zsh-hook
    add-zsh-hook chpwd update_terminal_cwd

    # Tell the terminal about the initial directory.
    update_terminal_cwd
  fi
fi

################################################################################
# Ruby
################################################################################

alias b="bundle exec"

# rbenv
if [[ -d "$HOME/.rbenv" ]]; then
  path=("$HOME/.rbenv/bin" $path)
  eval "$(rbenv init -)"
fi

################################################################################
# Node (via n)
################################################################################

export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"

################################################################################
# Python (via pyenv)
################################################################################

export PYENV_ROOT="$HOME/.pyenv"
if [[ -d "$PYENV_ROOT" ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

################################################################################
# Homebrew
################################################################################

export HOMEBREW_NO_ANALYTICS=1

# HOMEBREW_PREFIX=$(brew --prefix)
# if type brew &>/dev/null; then
#   if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
#     source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
#   else
#     for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
#       [[ -r "$COMPLETION" ]] && source "$COMPLETION"
#     done
#   fi
# fi

################################################################################
# fzf
################################################################################

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

################################################################################
# Miscellaneous
################################################################################

# Postgres.app
if [[ -d "/Applications/Postgres.app" ]]; then
  export PATH="$PATH:/Applications/Postgres.app/Contents/Versions/latest/bin"
fi

# Find the total memory % used by an app (e.g. Chrome or Firefox) that spawns
# many subprocesses. To use, pass a string (case-insensitive) that is shared by
# all the process names. Example:
#
#   total_memory firefox
#
total_memory() {
  paste -s -d'+' <(ps -eo pmem,comm | grep -i $1 | sed 's/^ //' | cut -d " " -f 1) | bc
}