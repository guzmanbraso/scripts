#! /bin/sh
# puppet-reports-stalker
# vagn scott, 21-jul-2011

days="+30"       # more than 30 days old

for d in `find /var/lib/puppet/reports -mindepth 1 -maxdepth 1 -type d`
do
         echo "Cleaning $d"
         find $d -type f -name \*.yaml -mtime $days |
         sort -r |
         tail -n +2 |
         xargs -n50 /bin/rm -f
done

exit 0
