#!/bin/bash

# This script will count down from the argument provided
# it will be used to show time and countdown by the second
# for a twitch stream that will begin then.
# when the countdown reaches zero, another message will show 
# that the stream is going live

if [ $# -eq 0 ]
then
  echo "No arguments supplied. Please provide the countdown time in seconds."
  exit 1
fi
start_time=$(date -d "$1" +%s)
current_time=$(date +%s)
countdown_time=$((start_time - current_time))
while [ $countdown_time -gt 0 ]
do
  minutes=$((countdown_time / 60))
  seconds=$((countdown_time % 60))
  echo -ne '\n' # Move to a new line to avoid overwriting the final countdown message
  echo -ne "Stream starting in $minutes minute(s) and $seconds second(s) at $(date -d @$start_time +%H:%M:%S)\r"
  echo -ne "\033[1A" # Move up one line
  sleep 1
  current_time=$(date +%s)
  countdown_time=$((start_time - current_time))
done
echo -ne '\n' # Move to a new line after the loop ends to avoid overwriting the final countdown message
echo "The stream is now going live!"
