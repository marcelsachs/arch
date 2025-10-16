#
# ~/.bashrc
#

[[ $- != *i* ]] && return

PS1='\[\033[1;38;5;226m\]\w $ \[\033[0m\]'

export EDITOR=vim

# save and reload history after each command
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

alias bh='cat ~/.bash_history'
alias bs='source ~/.bashrc'
alias grep='grep --color=auto'
alias la='ls -Al'
alias ll='ls -l'
alias ls='ls --color=auto'
