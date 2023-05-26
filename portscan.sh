#!/bin/bash

# PURPOSE
# check each day if you have accidentally opened any ports you do not know about
# also if your desired ports are open

# MAKE SURE YOU ARE ALLOWED TO SCAN THIS HOSTS
# I AM NOT RESPONSIBLE FOR YOUR ACTIONS

# trigger this with crontab every day
# 0	0	* 	* 	* 	/usr/local/bin/portscan.sh

# server:PORT1|PORT2|PORT3
TARGETS="host.example.org:443|80 host2.example.org:21|22"

# logfile
LOG=/var/log/portscan.log

# create temp files
scan_result=$(mktemp)
work_result=$(mktemp)

# put it in a function to get proper logging inside the script
scan ()
{
	# get target and ports from parameter
	target=$(echo $1 | cut -d: -f1)
	ports=$(echo $1 | cut -d: -f2)

	# create good looking timestamps
        print_date ()
        {
                echo "$(date +%F) [$1] $2"
        }

	# portscan itself
	# "-Pn" disables host discovery, assuming the host is online. This option skips the initial ping scan and treats all hosts as if they are online.
	# "-sS" specifies the TCP SYN scan technique, which sends SYN packets to the target ports to determine if they are open, closed, or filtered by a firewall.
	# "-T4" sets the timing template to "Aggressive." It increases the speed of the scan by sending more packets in a shorter timeframe, but it may also be more easily detected by intrusion detection systems.
	# -p 1-65535" specifies the range of ports to be scanned, from port 1 to port 65535. This covers the entire range of possible TCP and UDP ports.
        # "LANG=C" we search later for english words like closed/filtered	
	LANG=C nmap -Pn -sS -T4 -p 1-65535 ${target} > ${scan_result}
	if [ $? -eq 0 ]; then
		print_date "${target}" "OK: Portscan"
	else
		print_date "${target}" "ERROR: Portscan"
	fi

	# ignore closed ports and ports I am aware of
	cat ${scan_result} | grep ^[0-9] | egrep -v "closed|filtered" | egrep -v "${ports}" > ${work_result}

	if [ -s ${work_result} ]; then
		print_date "${target}" "ERROR: Unregistered Port open:"
		cat ${work_result}
	fi

	# check if ports that I want are still open
	IFS="|"
	for i in ${ports}
	do
		if ! (grep -q "^$i/" ${scan_result}); then
			print_date "${target}" "ERROR: Port $i not open"
		fi
	done

	# cleanup
	rm -f ${scan_result}
	rm -f ${work_result}
}

# clear log
> ${LOG}

# start and log
for target in ${TARGETS}
do
	scan ${target} | tee -a ${LOG} 2>&1
done
