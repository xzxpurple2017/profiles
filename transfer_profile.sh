#!/bin/bash

die () { ret=$1 ; shift ; echo -e "$@" ; exit $ret ; }
PROGNAME=$(basename "$0")

DESCRIPTION="
This script will scp various profile settings to a remote server.
Please enter your destination server or IP.
Note: Enter multiple destination with space. 
Example: ./$PROGNAME srv01 srv02 srv03
"
USAGE="
Usage: $progname -s SRV[,SRV[,...]] -u USERNAME [-r]

  -s  List of servers to copy to, comma-separated.
  -u  Username of recipient profiles.
  -r  Toggle to copy using sudo.
  -h  Display help statement.
"

declare -a srv_array=()
user=
sudo_flag=

while getopts ":s:u:rh" opt; do
	case $opt in
		s) IFS=, read -ra srv_array <<< "$OPTARG" ;;
		u) user="${OPTARG}";;
		r) sudo_flag="sudo" ;;	
		h) echo -e "${DESCRIPTION}${USAGE}" ; exit 0 ;;
		*) die 1 "Invalid command arguments.\n ${USAGE}";;
	esac
done

if [[ -z $user ]] && [[ -z ${srv_array[@]} ]] ; then
	die 1 "Please enter required arguments.\n ${USAGE}"
fi

echo -e "\n--------------"

for i in ${srv_array[@]} ; do
	echo -e "## $i"

	if [ "${i}" = "localhost" ] ; then
		echo "## Copying profiles locally"
		## If localhost, just copy files in user home
		$sudo_flag cp -p bashrc /home/${user}/.bashrc
		$sudo_flag cp -p bash_aliases /home/${user}/.bash_aliases
		$sudo_flag cp -p bash_functions /home/${user}/.bash_functions
		$sudo_flag cp -p vimrc /home/${user}/.vimrc
		$sudo_flag cp -p inputrc /home/${user}/.inputrc
		$sudo_flag cp -p screenrc /home/${user}/.screenrc
		cat /etc/*release | grep -q Ubuntu && $sudo_flag cp -p profile /home/${user}/.profile
		cat /etc/*release | grep -q CentOS && $sudo_flag cp -p profile /home/${user}/.bash_profile
	else

		## First, test if SSH connection is even possible with the user provided
		$sudo_flag ssh -o ConnectTimeout=5 "${user}"@"${i}" "true"
		ret=$?
		if [[ $ret -ne 0 ]] ; then
			echo "## ERROR - Could not connect to server $i - returned code $ret"
			echo -e "--------------\n"
			continue
		fi
	
		$sudo_flag scp -p bashrc "${user}"@"${i}":~/.bashrc
		$sudo_flag scp -p bash_aliases "${user}"@"${i}":~/.bash_aliases
		$sudo_flag scp -p bash_functions "${user}"@"${i}":~/.bash_functions
		$sudo_flag scp -p vimrc "${user}"@"${i}":~/.vimrc
		$sudo_flag scp -p inputrc "${user}"@"${i}":~/.inputrc
		$sudo_flag scp -p screenrc "${user}"@"${i}":~/.screenrc
	
		## Ubuntu based systems require a .profile file in the home directory
		## This does a check to see what distro is installed. 
		$sudo_flag ssh "${user}"@"${i}" "cat /etc/*release" | grep -q Ubuntu && $sudo_flag scp -p profile "${user}"@"${i}":~/.profile
		## CentOS systems use a .bash_profile file in the home directory
		$sudo_flag ssh "${user}"@"${i}" "cat /etc/*release" | grep -q CentOS && $sudo_flag scp -p profile "${user}"@"${i}":~/.bash_profile
	fi

	echo -e "--------------\n"
done

# vim: ts=4 sw=4
