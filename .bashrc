export PATH=/home/igarcia/bin:$PATH
export RELEASE_GROUP=inspire.symfony
export SFBIN=/sites/symfony/symfony-lib-tags-RELEASE_1_0_20/data/bin
export EDITOR=vim
export SVN_EDITOR=/usr/bin/vim
export GIT_SSL_NO_VERIFY=true

function set_bashrc_version ()
{
	revision='$Revision: 1.28 $'
	date='$Date: 2004/03/17 22:31:27 $'
	alias bashrcversion='echo "bashrc: $revision"'
	alias bashrcversiondate='echo "bashrc: $date"'
}

function set_bash_colors ()
{
	red="\[\033[31m\]"
	green="\[\033[32m\]"
	grey="\[\033[1;30m\]"
	yellow="\[\033[33m\]"
	blue="\[\033[34m\]"
	black="\[\033[30m\]"
	cyan="\[\033[36m\]"
	magenta="\[\033[35m\]"
	white="\[\033[00m\]"

	h_grey="\[\033[37m\]"
	h_red="\[\033[1;31m\]"
	h_green="\[\033[1;32m\]"
	h_yellow="\[\033[1;33m\]"
	h_blue="\[\033[1;34m\]"
	h_cyan="\[\033[1;36m\]"
	h_magenta="\[\033[1;35m\]"
	h_white="\[\033[1;00m\]"

}

function set_prompt ()
{

	set_bash_colors
	
	TERM_PROMPT="$white\t$white $h_green\u$black@$h_red\h{$REALNAME}$h_red:$black\W$white"

	case 'id -u' in
		0) PS1="${TERM_PROMPT} $red\#$white ";;
		*) PS1="${TERM_PROMPT} $red\$$white ";;
	esac

}


function set_aliases ()
{

  # SVN
	alias externals="svn pe svn:externals"
  alias sdiff="svn diff | less"
  alias sst="svn st | less"
  alias slog="svn log | less"

  # ACK
  alias ack="/home/igarcia/bin/ack --pager='less -R'"
	alias fack="ack -i '(function $@|class $@)' --php"

	# LISTS
	alias ls="ls -F"
	alias ll='ls -l'
	alias l='ls -a'
	alias la='ls -la'

	# VIM
	alias vim="vim -T dtterm"
  alias generate_tags="ctags -R -h \".php\" -R --exclude=\"\.svn\" --totals=yes --tag-relative=yes --PHP-kinds=+cf --regex-PHP='/abstract class ([^ ]*)/\1/c/' --regex-PHP='/interface ([^ ]*)/\1/c/' --regex-PHP='/(public |static |abstract |protected |private )+function ([^ (]*)/\2/f/'"

	# DIRECTORIES
	alias pdev="cd /sites/personaldev/igarcia"

	# SCRIPTS
	alias search2sync='php plugins/pluginSearch2Lib/batch/sync.php'

	# SYMFONY
	alias sf='./symfony'

  #PRM
  alias prm="prm -p6umazu_"
}

SVN="svn://subversion/symfony/"
PROJECT="/sites/personaldev/igarcia"

function ..()
{
  if [ "$1" ]; then
    level=$1
  else
    level=1
  fi
  counter=0
  while [ $counter -lt $level ]; do
    cd ..
    let counter+=1
  done
}

function scc()
{
	if [ "$1" ]; then
		cachefile1=cache/*/prod/config/config_$1.yml.php
		cachefile2=cache/*/dev/config/config_$1.yml.php						
		if [ -f $cachefile1 ]; then
			echo "Removing prod cache files..."
			rm -f $cachefile1
		fi
		if [ -f $cachefile2 ]; then
			echo "Removing dev cache files..."
			rm -f $cachefile2
		fi
		sctc
	else
		./symfony cc
	fi
}

function sctc()
{
	cachedir1=cache/*/prod/template
	cachedir2=cache/*/dev/template
	if [ -d $cachedir1 ]; then
		echo "Removing prod template cache..."
		rm -rf $cachedir1
	fi
	if [ -d $cachedir2 ]; then
		echo "Removing dev template cache..."
		rm -rf $cachedir2
	fi
	echo "Done."
}

function sfstart()
{
	./symfony fix-perms
	./symfony cc
}

function svnco()
{
	svn co $SVNPATH$1 $2
	cd $2
	sfstart
}

function svnlog()
{
	if [ "$2" ]; then
		svn log $SVNPATH$1 -v --limit=$2
	else
		svn log $SVNPATH$1 -v
	fi
}

function svnmerge()
{
	message="merge $1:HEAD from trunk"
	echo $message
	svn ci -m "$message"
}

function svnls()
{
	if [ "$1" ]; then
		svn ls $SVNPATH$1
	else
		svn ls $SVNPATH
	fi
}

function svnstash()
{
  svn diff > $1.patch
  svn revert -R .
}

function svnstashapply()
{
  patch -p0 < $1.patch
}

function h()
{
		if [ -z "$1" ]; then
			history
		else
			history | grep "$@"
		fi
}

# main
set_aliases
set_prompt
set_bashrc_version

# Screen settings
if [ "$TERM" = "screen" ]; then
  screen_set_window_title () {
    local HPWD="basename $PWD"
	case $HPWD in
		$HOME) HPWD="~";;
		*) HPWD=`basename "$HPWD"`;;
	esac
    printf '\ek%s\e\\' "$HPWD"
  }
  PROMPT_COMMAND="screen_set_window_title; $PROMPT_COMMAND"
fi

function svnup()
{
          svn up
                  ~aluneburg/bin/exemplarOverrides -p ${PWD##*/}
}

