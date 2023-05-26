#!/bin/bash

# PURPOSE
# this script will generate the status for your servers, your monitoring server will catch the files later

# trigger this script with crontab 

# log that will be catched from the monitoring server
report=/var/log/status.log

# function for better logging inside this script
main ()
{
        print_date ()
        {
                echo "$(date +%F) [$(hostname -a)] $1"
        }

        print_date "Uptime: $(uptime | awk '{print $3" "$4 }' | tr -d ',')"

	# I trigger rsnapshot everday, if this file is not available, rsnapshot was not started
        if ! [ -f "/tmp/backup.txt" ]; then
                print_date "ERROR: rsnapshot didn't run or still running"
        else
                cat /tmp/backup.txt
        fi

        rm -f /tmp/backup.txt
}

main > ${report}
