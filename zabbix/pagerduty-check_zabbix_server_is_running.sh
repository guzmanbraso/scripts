#!/bin/bash
#
# Check zabbix server is running or notify pagerduty
#
SERVICE_KEY="e93facc04764012d7bfb002500d5d1a6"
SERVER_NAME=$(hostname -f)

ps aux|pgrep zabbix_server >> /dev/null && exit 0 

JSON="{    
      \"service_key\": \"$SERVICE_KEY\",
      \"incident_key\": \"$SERVER_NAME zabbix_server not running\",
      \"event_type\": \"trigger\",
      \"description\": \"FAILURE zabbix_server IS NOT RUNNING\",
      \"client\": \"Sample Monitoring Service\",
      \"client_url\": \"https://monitoring.service.com\"
    }" \

echo $JSON
curl -H "Content-type: application/json" -X POST -d "$JSON" https://events.pagerduty.com/generic/2010-04-15/create_event.json