#!/bin/bash
#
# Simple script to search for a given fact and dump inventory of all nodes, one per file.
#
#
FACTNAME=$1
FACTVALUE=$2

curl -s -G -H  "Accept: application/json" 'http://localhost:8080/pdb/query/v4/nodes' --data-urlencode 'query=["=",["fact","'${FACTNAME}'"], "'${FACTVALUE}'"]' |
jq -r '.[]|[ .certname ]| @tsv' |
while IFS=$'\t' read -r host; do
  echo "Do something with $host"
  # Save one dump per host
  curl -s -G -H  "Accept: application/json" 'http://localhost:8080/pdb/query/v4/inventory' --data-urlencode 'query=["=","certname","'${host}'"]' > "node-${host}.inventory.log"
done
