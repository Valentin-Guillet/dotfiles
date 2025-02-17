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
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state

[ -f "$XDG_CONFIG_HOME"/bash/xdg_setup ] && . "$XDG_CONFIG_HOME"/bash/xdg_setup

# Auto run tmux
if [ -x "$(command -v tmux)" ]; then
    source "$XDG_CONFIG_HOME"/tmux/tmux_completion.sh

    if [ "$TMUX" = ignore ]; then
        unset TMUX
    elif [ -z "$TMUX" -a -z "$WT_SESSION" ]; then
        detached_session=$(tmux list-sessions -F '#S' -f '#{?session_attached,0,1}' 2> /dev/null | head -n 1)
        trap 'exec env TMUX=ignore bash -l' USR1
        if [ -n "$detached_session" ]; then
            tmux attach-session -t "$detached_session" \; set-environment TMUX_PPID $$
        else
            tmux new-session \; set-environment TMUX_PPID $$
        fi
        exit
    fi
fi

# Set up history
mkdir -p $XDG_CACHE_HOME/bash
HISTCONTROL=ignoreboth   # Don't put duplicate lines or lines starting with space
HISTSIZE=1000            # Set up length
HISTFILE="$XDG_CACHE_HOME"/bash/history
HISTFILESIZE=20000
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
fi

export VISUAL=$(which vim)
export EDITOR="$VISUAL"

# Additional setup, start by path (needed for some aliases)
[ -f "$XDG_CONFIG_HOME"/bash/paths ] && . "$XDG_CONFIG_HOME"/bash/paths
[ -f "$XDG_CONFIG_HOME"/bash/local_paths ] && . "$XDG_CONFIG_HOME"/bash/local_paths

[ -f "$XDG_CONFIG_HOME"/bash/aliases ] && . "$XDG_CONFIG_HOME"/bash/aliases
[ -f "$XDG_CONFIG_HOME"/bash/local_aliases ] && . "$XDG_CONFIG_HOME"/bash/local_aliases

[ -f "$XDG_CONFIG_HOME"/bash/functions ] && . "$XDG_CONFIG_HOME"/bash/functions
[ -f "$XDG_CONFIG_HOME"/bash/local_functions ] && . "$XDG_CONFIG_HOME"/bash/local_functions

[ -f "$XDG_CONFIG_HOME"/bash/python_venv ] && . "$XDG_CONFIG_HOME"/bash/python_venv
