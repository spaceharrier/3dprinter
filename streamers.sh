
#/bin/bash

# Turn light on or off depending on whether anyone is accessing the camera feed
# Check for connections to given port, dedupe against local IP addresses, trigger if there are IPs remaining
# External scripts called as on/off events

ON_CMD="/home/pi/scripts/lighton.sh"
OFF_CMD="/home/pi/scripts/lightoff.sh"

# Minimum interval for triggering on/off events, to avoid thrashing
INTERVAL=5

# Set initial interval
THRESHOLD=`date +%s`
THRESHOLD=$(( $THRESHOLD + $INTERVAL ))
echo Threshold time is [$THRESHOLD]

while true; do
  sleep 3

  STREAMING_IPS=`netstat -nt -p tcp 2>/dev/null | awk '$4 ~ /8080/' | awk '{ print $5 }' | cut -d ":" -f1 | sort`

  # Timestamp for this evaluation
  CURRENT_TIME=`date +%s`

  if ! [[ -z $STREAMING_IPS ]]
  then 

    LOCAL_IPS=`ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{ print $2 }' | sort`
    echo Streaming IPs [$STREAMING_IPS]
    echo Local IPs     [$LOCAL_IPS]

    TOTAL_REMOTES=`comm -23 <(echo -n "$STREAMING_IPS") <(echo -n "$LOCAL_IPS") | wc -l`
    if [ "$TOTAL_REMOTES" -gt "0" ]
    then 
      echo Remotes [$TOTAL_REMOTES]
      if [ $CURRENT_TIME -gt $THRESHOLD ]
      then
        echo Triggering switch on: past threshold time
        THRESHOLD=$(( $CURRENT_TIME + $INTERVAL ))
        echo Updated threshold time is [$THRESHOLD]
        eval ${ON_CMD}
      else
        echo Skip switch on: insufficient interval [$CURRENT_TIME] vs [$THRESHOLD]
      fi
    else
      echo No remote streaming connections
    fi  
  else
    echo No streaming connections
    if [ $CURRENT_TIME -gt $THRESHOLD ]
     then
        echo Triggering switch off: past threshold time
        THRESHOLD=$(( $CURRENT_TIME + $INTERVAL ))
        echo Updated threshold time is [$THRESHOLD]
        eval ${OFF_CMD}
     else
        echo Skip switch off: insufficient interval [$CURRENT_TIME] vs [$THRESHOLD]
     fi
  fi 
done