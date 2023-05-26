#!/bin/bash

# PURPOSE
# This script will send you a daily summary of your zabbix problems

# CONFIG
SERVER=zabbix.example.org
TOKEN=xxxxx

# you can trigger this with crontab or use status_all.sh

## Reference
# https://www.zabbix.com/forum/zabbix-help/387124-how-to-get-latest-problems-using-zabbix-api
# https://stackoverflow.com/questions/39139107/how-to-format-a-json-string-as-a-table-using-jq

## curl = silent, allow self signed cert
## methode is trigger.get - Abfrage: Zeige alle aktiven trigger und filtere nach denen, die gerade ein Problem haben
## show all active triggers and filter the one with problems
## sortfield - priority ascending sort
## auth - please see reference above to create token
## jq - makes it beautiful

/usr/bin/curl -s -k -X POST https://${SERVER}/zabbix/api_jsonrpc.php -H 'Content-Type:application/json' -d '{"jsonrpc":"2.0","method":"trigger.get","params": { "selectHosts": "extend", "active": 1, "filter": { "value": 1 }, "sortfield": "priority", "sortorder": "DESC" }, "auth":"${TOKEN}","id": 1}' | /usr/bin/jq -r '.result[] | "(" + .priority + ")" + .hosts[].host + " -> " + .description'
