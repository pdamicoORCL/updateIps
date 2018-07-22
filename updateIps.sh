#! /bin/bash
#
# Tue, Jun 12, 2018  6:41:26 AM
#
# updateIps.sh
#
#
#


# 2018-06-13 but don't get rid of 2017 entries
#
#
# Wed, Jul  4, 2018  7:17:25 AM - Added logic to reset ~/ips.json
#                                 so there won't be a mismatch of 
#                                 line counts between
#                                 ips.json and ips_new.txt
#                                 if there are no new ips
# Sun, Jul 22, 2018  9:38:05 AM
# Sun, Jul 22, 2018  9:57:11 AM


if [ -f "~/ips.json" ] ; then
    rm ~/ips.json
    touch ~/ips.json
fi



LOGFILE="/cygdrive/c/Users/pdamico/ownCloud/gmail/logs.csv"
GZ_BACKUP_DIR="/cygdrive/c/Users/pdamico/ownCloud/Tableau/Postgres"

# 0. Backup the database to ips_Y_m_d.sql e.g. pgs_2018_07_01.sql.gz
#
#

THEDATE=$(date +%Y_%m_%d) 
# pg_dump -U pdamico -h localhost  -d ips -f ips_$x.sql -C -n ips
pg_dump -U pdamico -h localhost  -d ips -C -n ips | gzip -9c >$GZ_BACKUP_DIR/ips_$THEDATE.sql.gz

# 1. Get all the ip address from logs.csv. Store them in ~/ipdetails.csv
#

egrep LAN\ access\ from\ remote $LOGFILE | awk -F \| -f ~/scrapeLogs.awk  >~/ip_all.in

cut -d \| -f1,2 ~/ip_all.in >~/ipdetails.csv

psql -q -U pdamico -h localhost ips -c 'DELETE FROM ips.ip_all WHERE EXTRACT(YEAR FROM ipdate)=2018;'
cat ~/ip_all.in | psql -U pdamico -h localhost ips -c "copy ips.ip_all from stdin WITH ( FORMAT csv, DELIMITER '|');"


# 2. Get unique IPs from ~/ipdetails.csv. Store them in ip_candidates.txt

cut -d \| -f2 ~/ipdetails.csv | sort -u >~/ip_candidates.txt

# 3. Re-populate ips table with ~/ipdetails.csv
#    2018-06-13 but don't get rid of 2017 entries

# psql -q -U ips -h localhost ips -c 'TRUNCATE TABLE ipdetail;'
#
psql -q -U ips -h localhost ips -c 'DELETE FROM ipdetail WHERE EXTRACT(YEAR FROM ipdate)=2018;'
cat ~/ipdetails.csv | psql -U ips -h localhost ips -c 'copy ipdetail from stdin WITH (FORMAT CSV, DELIMITER "|");'

psql -U ips -h localhost ips -c 'TRUNCATE TABLE ip_candidates;'
cat ~/ip_candidates.txt | psql -U ips -h localhost ips -c "copy ip_candidates from stdin;"

# 4. Now get a list of ips that aren't in the master table yet. Place them in ips_new.txt

psql -q -t -U ips -h localhost ips -c "select ip from ips.v_ip_orphans" -A -F \| --pset footer >~/ips_new.txt

totalLines=$(wc -l ~/ips_new.txt | cut -d' ' -f1)

if [ $totalLines -gt 0 ]; then 
  echo $totalLines New IPs
  python ./getIpInfo.py
  cat ~/ips.json | psql -U ips -h localhost ips -c "copy ips.ips from stdin;";
else
 echo No New IPs
fi

printf "\n\nHere are the results\n\nThe number of lines\nshould be the same\n-------------------\n" && wc ips.json ips_new.txt

