
alias cpr='cp -r'
alias rmr='rm -r'

alias cd..='cd ..'
alias cdrl='cd ~/Documents/Deep-RL-agents'

alias d='du -hd 1'
alias gifspeed='find $(pwd) -name "*.gif" -exec convert -delay 2x100 {} {} \;'

alias py=python
alias run='py main.py'

alias config='vim ~/.bash_aliases; source ~/.bashrc'
alias configg='vim ~/.bashrc; source ~/.bashrc'

alias datamnt='sudo mount /dev/sda1 /media/valentin/DATA'

function next_folder {
	cmd=$1
	if [[ "$cmd" =~ ^cd\ ..[/\.\.]+$ ]]
	then
		echo ${cmd%/*}
	elif [ "$cmd" == "cd .." ]
	then
		echo cd .
	else
		if [[ "$cmd" != cd* ]]
		then
			cmd="cd ."
		fi
		cmd="$cmd/`ls -1t --group-directories-first ${cmd:3} 2>/dev/null | grep -m 1 ""`"
		if [ ! -d ${cmd:3} ]
		then
			echo $1
		else
			echo $cmd
		fi
	fi
}

function prev_folder {
	cmd=$1
	if [[ "$cmd" =~ ^cd\ ..[/\.\.]*$ ]]
	then
		echo $cmd/..
	elif [ -z "$cmd" ] || [ "$cmd" == "cd ." ]
	then
		echo cd ..
	else
		echo ${cmd%/*}
	fi
}

function down_folder {
	cmd=$1
	cmd="cd `realpath ${cmd:3}`"
	wocd=${cmd:3}
	n_dir=`ls -1t --group-directories-first ${wocd%/*}/ 2>/dev/null | grep -n ${cmd##*/}`
	n_dir=${n_dir%%:*}
	ccm=`ls -1t --group-directories-first ${wocd%/*} 2>/dev/null | sed -n "$((n_dir + 1)) p"`
	if [ -z $ccm ]
	then
		echo $1
	else
		cmd="${wocd%/*}/$ccm"
		if [ -d $cmd ]
		then
			echo "cd $cmd"
		else
			echo $1
		fi
	fi
}

function up_folder {
	cmd=$1
	cmd="cd `realpath ${cmd:3}`"
	wocd=${cmd:3}
	n_dir=`ls -1t --group-directories-first ${wocd%/*}/ 2>/dev/null | grep -n ${cmd##*/}`
	n_dir=${n_dir%%:*}
	if [ $n_dir == 1 ]
	then
		echo $1
	else
		cmd="${wocd%/*}/`ls -1t --group-directories-first ${wocd%/*} 2>/dev/null | sed -n \"$((n_dir - 1)) p\"`"
		if [ -d $cmd ]
		then
			echo "cd $cmd"
		else
			echo $1
		fi
	fi
}
