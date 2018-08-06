# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# Use emacs terminal to get Ctrl-a and Ctrl-e to work
set -o emacs

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
HISTTIMEFORMAT="%m/%d/%y %T "
shopt -s histappend
PROMPT_COMMAND='printf "\033]0;%s:%s\007" "${USER}@`hostname -s`" "${PWD/#$HOME/~}"'
PROMPT_COMMAND="history -a;history -n;$PROMPT_COMMAND"

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
  # We have color support; assume it's compliant with Ecma-48
  # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
  # a case would tend to support setf rather than setaf.)
  color_prompt=yes
    else
  color_prompt=
    fi
fi

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

determine_git_changes() {
	git_color=32   # Green text
	## Good idea but this is too slow for prompt
	#git remote update >/dev/null 2>&1
	#git status -uno 2> /dev/null | grep -q 'Your branch is behind' && git_color=35
	[[ -z $(git status -uno --porcelain 2> /dev/null) ]] ||	git_color=31   # Red text
	echo $git_color
}

if [ "$color_prompt" = yes ]; then
    #PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w \$\[\033[00m\] '
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w\[\033[00;$(determine_git_changes)m\]$(parse_git_branch) \[\033[01;34m\]\$\[\033[00m\] '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*|cygwin*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Function definitions.
# You many want to put all your functions into a separate file like
# ~/.bash_functions, instead of adding them here directly.

if [ -f ~/.bash_functions ] ; then
	. ~/.bash_functions
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# This adds support for SSH sessions in screen
# Source: https://gist.github.com/martijnvermaat/8070533
if [[ -S "$SSH_AUTH_SOCK" && ! -h "$SSH_AUTH_SOCK" ]]; then
    ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock;
fi
export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock;

# AWS EC2 tools
export EC2_BASE=/opt/ec2
export EC2_HOME=$EC2_BASE/tools

# GPG config  ------------------------------------------------------------
#
# Check if running Ubuntu with Systemd
# If it is, check if 'pcscd' process is running
# If not running, alert user to restart it using 'sudo'
declare -a gpg_err_msg=()

hostnamectl | grep -oP 'Operating System: Ubuntu 1[6789]\..*' -q
ret=$?
if [[ $ret -eq 0 ]] ; then
  systemctl is-active --quiet pcscd
  ret=$?
  if [[ $ret -ne 0 ]] ; then
  	msg="'pcscd' is not running. Please start via systemctl as root."
	gpg_err_msg+=("${msg}")
  fi
fi

# GPG config
# Change to 'yes' if you have a laptop or desktop with a Yubikey
# You can also toggle to dynamically detect the Yubikey
# NOTE: On Ubuntu 18.04, pcscd systemd unit file does not work and requires 
# a modification to start up automatically
yubikey='no'
check_for_card='yes'
if [[ "$check_for_card" = "yes" ]] ; then
  gpg --card-status > /dev/null 2>&1
  ret=$?
  if [[ $ret -eq 0 ]] ; then
  	yubikey='yes'
  fi
fi

if [[ "$yubikey" = "yes" ]] ; then
  # Check if agent is running
  if ! pgrep -x gpg-agent > /dev/null 2>&1 ; then
    rm -rf ${HOME}/.gnupg/S.gpg-agent
    rm -rf /var/run/user/1000/gnupg/
  fi
  envfile="${HOME}/.gnupg/gpg-agent.env"
  if ( [[ ! -e "${HOME}/.gnupg/S.gpg-agent" ]] && \
       [[ ! -e "/var/run/user/$(id -u)/gnupg/S.gpg-agent" ]] );
  then
    killall pinentry > /dev/null 2>&1
    gpgconf --reload scdaemon > /dev/null 2>&1
    ret=$?
    if [[ $ret -ne 0 ]] ; then
    	msg="Could not gpgconf reload the scdaemon"
  	gpg_err_msg+=("${msg}")
    fi
    pkill -x -INT gpg-agent > /dev/null 2>&1
    gpg-agent --daemon --enable-ssh-support > ${envfile}
    ret=$?
    if [[ $ret -ne 0 ]] ; then
      msg="Could not use gpg-agent to enable SSH support"
  	gpg_err_msg+=("${msg}")
    fi
    echo "Configured Yubikey to integrate with SSH agent"
    [[ -z ${gpg_err_msg[@]} ]] || echo -e "WARN: some errors\n"
  fi
  
  # Wake up smartcard to avoid races
  gpg --card-status > /dev/null 2>&1
  ret=$?
  if [[ $ret -ne 0 ]] ; then
    msg="Could not get Yubikey status. Perhaps restart 'pcscd' service"
    gpg_err_msg+=("${msg}")
  fi
  
  source "${envfile}"
  
  # Output any errors while trying to configure GPG and Yubikey
  if [[ -n ${gpg_err_msg[@]} ]] ; then
    for e in "${gpg_err_msg[@]}" ; do
    	echo "# ERROR -- ${e}"
    done
  fi
fi
# ----------------------------------------------------------------------
# Xclip settings to make it behave like pbcopy
if [[ -f /tmp/.xclipinstalled ]] ; then
	alias pbcopy='xclip -selection clipboard'
	alias pbpaste='xclip -selection clipboard -o'
else
	cat /etc/*release | grep -q Ubuntu
	ret=$?
	if [[ $ret -eq 0 ]] ; then
		dpkg -l | grep -q xclip >/dev/null 2>&1
		ret=$?
		if [[ $ret -eq 0 ]] ; then
			touch /tmp/.xclipinstalled
			alias pbcopy='xclip -selection clipboard'
			alias pbpaste='xclip -selection clipboard -o'
		fi
	fi
fi
# ----------------------------------------------------------------------
#
## SSH agent settings
#SSH_ENV="$HOME/.ssh/environment"
#
#function start_agent {
#    echo "Initialising new SSH agent..."
#    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
#    echo succeeded
#    chmod 600 "${SSH_ENV}"
#    . "${SSH_ENV}" > /dev/null
#    /usr/bin/ssh-add;
#        # loop to add SSH private keys
#    for f in ~/.ssh/* ; do
#        file_type=$( file $f )
#        matching_str="private key"
#        if [[ "$file_type" =~ "$matching_str" ]] ; then
#            ssh-add "$f"
#        fi
#    done
#}
#
## Source SSH settings, if applicable
#
#if [ -f "${SSH_ENV}" ]; then
#    . "${SSH_ENV}" > /dev/null
#    #ps ${SSH_AGENT_PID} doesn't work under cywgin
#    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
#        start_agent;
#    }
#else
#    start_agent;
#fi
