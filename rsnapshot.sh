#!/bin/bash

# PURPOSE
# This script is for your backup server. It will retrieve all rsnapshot backups from your hosts.
# Make sure you have your ssh key in place and configured all hosts in .ssh/config.

# trigger this with crontab every day
# 30 	1 	* 	* 	* 	/usr/local/bin/rsnapshot.sh daily
# 0 	6  	* 	* 	7 	/usr/local/bin/rsnapshot.sh weekly
# 0 	7  	1 	* 	* 	/usr/local/bin/rsnapshot.sh monthly
# 0 	8  	1 	1 	* 	/usr/local/bin/rsnapshot.sh yearly

# CONFIG
# email will be sent to this addr
EMAIL=user@example.org

# emails are coming from $HOSTNAME@$DOMAIN
DOMAIN=example.org

# file declatrion
tmp_log=$(mktemp -t)
tmp_hosts=$(mktemp -t)
tmp_mail=$(mktemp -t)
backup_log=/backup/rsnapshot/log/backup.$(date +'%A').log
backup_log_err=/backup/rsnapshot/log/backup.$(date +'%A').err
mode=$1

# get ssh key
source /root/.ssh/agent.sh > /dev/null

# rotate logfile
mv /var/log/rsnapshot.log /var/log/rsnapshot.log.1

# perform rsnapshot
/usr/bin/rsnapshot -c /etc/rsnapshot.conf ${mode} > ${backup_log} 2> ${backup_log_err}
status=$?

# copy to latest backup log
cat /var/log/rsnapshot.log >> ${backup_log}

# check which hosts are in config for backup to check them later
cat /etc/rsnapshot.conf | grep ^backup > ${tmp_hosts}

# get backup stats from log
grep -i "total.*:" ${backup_log} | egrep -v "sent|received" > ${tmp_log}

# get backup status
cat /var/log/rsnapshot.log |grep $(date +"%d/%b/%Y") | egrep "started|completed" > ${tmp_mail}
echo "----------------------------" >> ${tmp_mail}

# start with this value for checking each host
count=2

# check each host in backup file
while read host
do
        echo $host >> ${tmp_mail}
        head -n ${count} ${tmp_log} | tail -n 2 >> ${tmp_mail}
        count=$(echo $count + 2 | bc) >> ${tmp_mail}
        echo "----------------------------" >> ${tmp_mail}

done < ${tmp_hosts}

# check backup of each host
if [ ${status} -eq 0 ]; then
        status=OK
        echo "$(date +%F) [$(hostname -a)] OK: rsnapshot" >> /tmp/backup.txt
else
        status="ERROR $status"
        echo "----------------------------" >> ${tmp_mail}
	cat ${backup_log_err} >> ${tmp_mail}
        echo "$(date +%F) [$(hostname -a)] ERROR: rsnapshot" >> /tmp/backup.txt
fi

# send backup
cat ${tmp_mail} | mail -s "$(hostname) Backup [$status] $(date +'%A')" ${EMAIL}

# cleanup
rm -f ${tmp_log}
rm -f ${tmp_hosts}
rm -f ${tmp_mail}
