#!/bin/bash
#
# This script was done to deal with common troubleshooting when using puppet environments as branches in git 
# together with git submodules.
#
# It assumes your puppet master is installed on /etc/puppet and inside exists a folder per branch/environment you have.
#
# To avoid issues it run all git commands as the user that takes care of auto populate those branches, in our case
# is www-data. 
#
BRANCH=$1
ENVROOT="/etc/puppet"
USER='www-data'

if [ "$1" == "" ]; then
	echo "You must provide branch name as only argument"
	exit
fi

echo "-------- Checking Branch $BRANCH"

echo -n "- Branch folder: "

if [ ! -d ${ENVROOT}/${BRANCH} ]; then
	echo "FAIL - Folder '$BRANCH' does not even exist, have you commited at least once after checking it out?"
	exit
else
	echo "OK - It does exist, weight: "`du -ms ${ENVROOT}/${BRANCH}|awk '{ print $1 }'`"mb"
fi

echo "- Branch submodule status:"
sudo -u www-data sh -c "cd ${ENVROOT}/${BRANCH}; git submodule status"

echo 
echo "- Calling submodule update --init (no output means OK!):"

sudo -u www-data sh -c "cd ${ENVROOT}/${BRANCH}; git submodule update --init"







	