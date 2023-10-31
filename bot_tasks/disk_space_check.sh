#!/bin/bash

# Check if the disk check log file exists
if [ -f "disk_check.log" ]; then
  # Get the last run time from the log file
  last_run=$(date -d "$(cat disk_check.log)" +%s)
  # Get the current time
  now=$(date +"%s")
  # Calculate the number of seconds in a day
  seconds_in_a_day=$((24*60*60))
  # If the last run was less than 1 day ago, exit
  if [ $(($now - $last_run)) -lt $seconds_in_a_day ]; then
    exit 0
  fi
fi

# Get the disk usage for root and /home mounts
disk_usage_root=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
disk_usage_home=$(df /home | tail -1 | awk '{print $5}' | sed 's/%//')

# If disk usage for either root or /home is more than 50%, write the timestamp to the log file
if [ $disk_usage_root -gt 50 ] || [ $disk_usage_home -gt 50 ]; then
  # Get the hostname of the machine
  host_name=$(hostname)
  # Identify which disk is running low
  if [ $disk_usage_root -gt 50 ]; then
    echo "Disk '/' on $host_name is running low"
  fi
  if [ $disk_usage_home -gt 50 ]; then
    echo "Disk '/home' on $host_name is running low"
  fi
fi
 echo "$(date +%Y-%m-%d\ %H:%M:%S)" > "disk_check.log"