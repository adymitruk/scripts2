#!/bin/bash
THRESHOLD=90
TIME_PERIOD="1 minutes ago"

DEBUG=0
for arg in "$@"
do
  if [ "$arg" == "--debug" ]
  then
    DEBUG=1
    echo DEBUG: debug set
  fi
done
last_run=$(date -r "disk_check.log" +%s)
[ $DEBUG -eq 1 ] && echo "DEBUG: Last run: $(date -d @$last_run)"
time_period_ago=$(date -d"$TIME_PERIOD" +%s)
[ $DEBUG -eq 1 ] && echo "DEBUG: Time period ago: $(date -d @$time_period_ago)"

if [ $last_run -ge $time_period_ago ]
then
  [ $DEBUG -eq 1 ] && echo "DEBUG: Script was run less than $TIME_PERIOD. Exiting..."
  exit 0
else
  [ $DEBUG -eq 1 ] && echo "DEBUG: Script was run more than $TIME_PERIOD. Continuing..."
fi


mount_points=("/" "/home")
[ $DEBUG -eq 1 ] && echo DEBUG: mount points: "${mount_points[@]}"

over_threshold=()

for mount_point in "${mount_points[@]}"
do
  disk_usage=$(df $mount_point | tail -1 | awk '{print $5}' | sed 's/%//')
  [ $DEBUG -eq 1 ] && echo "DEBUG: Disk usage for $mount_point: $disk_usage%"
  if [ $disk_usage -gt ${THRESHOLD} ]; then
    over_threshold+=("$mount_point: $disk_usage%")
  fi
done
[ $DEBUG -eq 1 ] && echo "DEBUG: Over threshold: ${over_threshold[@]}"

if [ ${#over_threshold[@]} -ne 0 ]; then
  echo "The following mount points are over the threshold:"
  for i in "${over_threshold[@]}"
  do
    echo $i
  done
else
  [ $DEBUG -eq 1 ] && echo DEBUG: no mount points are over the threshold
fi
current_date=$(date +%Y-%m-%d\ %H:%M:%S)
[ $DEBUG -eq 1 ] && echo DEBUG: $current_date
echo $current_date > "disk_check.log"
