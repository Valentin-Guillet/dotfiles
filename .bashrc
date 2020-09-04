# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Set dotfiles location
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache

export INPUTRC="$XDG_CONFIG_HOME"/readline/inputrc
export PYTHONSTARTUP="$XDG_CONFIG_HOME"/python/pythonrc.py

mkdir -p "$XDG_CACHE_HOME"/history
export ICEAUTHORITY="$XDG_CACHE_HOME"/ICEauthority
export XAUTHORITY="$XDG_CACHE_HOME"/Xauthority
export LESSHISTFILE="$XDG_CACHE_HOME"/history/less_history
export CUDA_CACHE_PATH="$XDG_CACHE_HOME"/nv

# Auto launch tmux
if command -v tmux > /dev/null
then
    if tmux ls 2>/dev/null | grep -v "(attached)" && [ -z "$SSH_CONNECTION" ]
    then
        n_session=$(tmux ls | grep -v "(attached)" | head -n 1 | cut -d : -f 1)
        [[ ! $TERM =~ screen || $SSH_CLIENT ]] && [ -z "$TMUX" ] && exec tmux attach -t "$n_session"
    else
        [[ ! $TERM =~ screen || $SSH_CLIENT ]] && [ -z "$TMUX" ] && exec tmux
    fi
    source "$XDG_CONFIG_HOME"/tmux/tmux_completion.sh
fi

# Set up history
HISTCONTROL=ignoreboth   # Don't put duplicate lines or lines starting with space
HISTSIZE=1000            # Set up length
HISTFILE="$XDG_CACHE_HOME"/history/bash_history
HISTFILESIZE=2000
shopt -s histappend      # Append to the history file, don't overwrite it

# Write to the history after every command without waiting exit
PROMPT_COMMAND="history -a;$PROMPT_COMMAND"

# Check the window size after each command and update the values of LINES and COLUMNS
shopt -s checkwinsize

# Authorize "**" pattern to match zero or more dirs and subdirs
shopt -s globstar

# Make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Set up fancy prompt
if [[ "$TERM" == xterm-color || "$TERM" == *-256color ]]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
if [[ "$TERM" == xterm* || "$TERM" == rxvt* ]]; then
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
fi

# Enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

EDITOR=/usr/bin/vim

# Alias definitions
[ -f "$XDG_CONFIG_HOME"/bash/aliases ] && . "$XDG_CONFIG_HOME"/bash/aliases
[ -f "$XDG_CONFIG_HOME"/bash/local_aliases ] && . "$XDG_CONFIG_HOME"/bash/local_aliases
[ -f "$XDG_CONFIG_HOME"/bash/functions ] && . "$XDG_CONFIG_HOME"/bash/functions

if [[ $PATH != */opt/miniconda3/bin* ]]
then
    export PATH="/opt/miniconda3/bin:"$PATH
fi

