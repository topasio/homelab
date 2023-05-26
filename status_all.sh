#!/bin/bash

# PURPOSE
# check your servers every daily if they are running and rsnapshot was successful
# you can also check if your website is available

# IMPORTANT
# you need to perform the status.sh on every host to generate the report

# CONFIG
# login to this hosts and perform status.sh
HOSTS="host1 host2 host3"

# check if impressum is available on website
WEBSITES="http://www.example.org"
EMAIL="user@example.org"

# file declaration
report=/var/log/status.log
report_all=/var/log/status_all.log
report_mail=/var/log/status_mail.log
tmp=/var/log/status.tmp

# function for better logging inside this script
main ()
{
	## pretty timestamps
	print_date ()
	{
		echo -e "$(date +%F) [$(hostname -a)] $1\n"
	}

	## check if impressum is found on my website
	check_web ()
	{
		for i in $1
		do
			site=$(echo $i | cut -d / -f3)
			if (curl $i 2>/dev/null | grep -iq impressum); then
				print_date "${site} online"
			else
				print_date "ERROR: ${site} offline"
			fi
		done
	}

	## check if host is available and report file was generated
	## NOTE: status.sh must be installed on server
	check_host ()
	{
		if (ping -c 1 $1 >/dev/null 2>&1); then

			ssh -oBatchMode=yes -oConnectTimeout=10 -oPasswordAuthentication=no $1 "cat ${report}"

			if [ $? -ne 0 ]; then
				print_date "ERROR: $1 host up but can't connect via. ssh"
			fi
		else
			print_date "ERROR: $1 not available"
		fi
	}

	# run function for each host
	for host in ${HOSTS}
	do
		check_host ${host}
	done

	# run function for each website
	for website in ${websites}
	do
		check_web ${website}
	done
}

# import ssh key
source /root/.ssh/agent.sh > /dev/null

# run checks
main > ${report_all}

# prepare daily mail
> ${report_mail}

# good place to include zabbix status
echo -e "\n---- Zabbix ----" >> ${report_mail}
/usr/local/bin/zabbix_status.sh >> ${report_mail}

# include now system status
echo -e "\n---- Systeme ----" >> ${report_mail}

# send mails and change subject when an error occurs
if (grep -iq "error" ${report_all}); then
	sort -k3 ${report_all} >> ${report_mail}
	cat ${report_mail} | mail -s "[ERROR] Daily Status" -a "Content-Type: text/plain; charset=UTF-8" ${EMAIL}
else
	sort -k3 ${report_all} | grep -v ^\$ >> ${report_mail}

	cat ${report_mail} | mail -s "[OK] Daily Status" -a "Content-Type: text/plain; charset=UTF-8" ${EMAIL}
fi
