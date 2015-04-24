#!/bin/bash
#
# Script to call cachepurge url's to force nginx clear a cache entry.
# Created to deal with setups where there are many nginx servers for a single domain.
# Allow to hardcode IP's of nginx servers which are not in the domain DNS.

URL=$1
DOMAIN=`echo $URL|awk -F '/' '{ print $1 }'` 
URLPATH=$(echo $URL | grep / | cut -d/ -f2-)
FIXED_NODES="1.1.1.1 1.1.1.2 1.1.1.3"

if [[ "$1" == "" ]]; then
	echo "Usage: $0 URL-WITHOUT-HTTP://"
	echo "Eg: $0 www.domain.com/imagepurge/css/file.css"
	echo "Eg2: $0 www.domain.com/cachepurge/us"
	exit 0
fi
echo "Cleaning url path $URLPATH from domain $DOMAIN..."

echo

for fixednode in $FIXED_NODES; do
	CURL_RUN=`/usr/bin/curl -I -s --header "Host: $DOMAIN" "http://$fixednode/$URLPATH"|grep ^HTTP|awk '{ print $2 }'`
	echo "Called purge url in fixed node $fixednode, status returned: $CURL_RUN"
done

# Call purge on every nginx that dns resolves to...
for webserver_ip in `dig @8.8.8.8 $DOMAIN|grep ^$DOMAIN|awk '{ print $NF }'`; do
	CURL_RUN=`/usr/bin/curl -I -s --header "Host: $DOMAIN" "http://$webserver_ip/$URLPATH"|grep ^HTTP|awk '{ print $2 }'`
	echo "Called purge url at $webserver_ip, status returned: $CURL_RUN"
done 
