#!/bin/bash

PROGNAME=$(basename "$0")

MESSAGE="
This script will scp various profile settings to a remote server.
Please enter your destination server or IP.
Note: Enter multiple destination with space. 
Example: ./$PROGNAME srv01 srv02 srv03
"

echo -e "$MESSAGE"
read -a srv_array

echo -e "\nNow enter remote user:"
read user
echo -e "\n-----------------------"

for i in ${srv_array[@]} ; do
	echo -e "## $i"

	## First, test if SSH connection is even possible with the user provided
	ssh -o ConnectTimeout=5 "${user}"@"${i}" "true"
	ret=$?
	if [[ $ret -ne 0 ]] ; then
		echo "## ERROR - Could not connect to server $i - returned code $ret"
		echo -e "--------------\n"
		continue
	fi

	scp -p bashrc "${user}"@"${i}":~/.bashrc
	scp -p bash_aliases "${user}"@"${i}":~/.bash_aliases
	scp -p bash_functions "${user}"@"${i}":~/.bash_functions
	scp -p vimrc "${user}"@"${i}":~/.vimrc
	scp -p inputrc "${user}"@"${i}":~/.inputrc
	scp -p screenrc "${user}"@"${i}":~/.screenrc

	## Ubuntu based systems require a .profile file in the home directory
	## This does a check to see what distro is installed. 
	ssh "${user}"@"${i}" "cat /etc/*release" | grep -q Ubuntu && scp -p profile "${user}"@"${i}":~/.profile
	## CentOS systems use a .bash_profile file in the home directory
	ssh "${user}"@"${i}" "cat /etc/*release" | grep -q CentOS && scp -p profile "${user}"@"${i}":~/.bash_profile

	echo -e "--------------\n"
done


