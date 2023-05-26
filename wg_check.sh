#!/bin/bash

# PURPOSE
# These scripts check the status of your Wireguard connection and restart it if the server IP address has changed. 
# This often happens when working with endpoints that have a dynamic IP address.

INTERFACE=wg0
SERVER=wg.example.org
       
wg_ip=$(wg show ${INTERFACE} endpoints | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")   
current_ip=$(dig +short ${SERVER})

if [ "$current_ip" != "$wg_ip" ]; then
	echo "ip changed"
	/usr/sbin/service wg-quick@${INTERFACE} restart
#else 
#	echo "ip not changed"
fi
