#!/bin/bash

# This script will count down from the argument provided
# it will be used to show time and countdown by the second
# for a twitch stream that will begin then.
# when the countdown reaches zero, another message will show 
# that the stream is going live

print_help() {
  echo "Usage: $0 <countdown_time_in_seconds> [end_message] [countdown_message]"
  echo
  echo "Arguments:"
  echo "  countdown_time_in_seconds  The countdown time in seconds (required)"
  echo "  end_message                The message to display when the countdown reaches zero (optional)"
  echo "  countdown_message          The message to display during the countdown (optional)"
  echo
  echo "Example:"
  echo "  $0 60 'The stream is now going live!' 'Stream starting in'"
}

if [ "$1" == "--help" ]; then
  print_help
  exit 0
fi

if [ $# -lt 1 ]; then
  echo "No arguments supplied. Please provide the countdown time in seconds."
  exit 1
fi

# Ensure the input is a valid number
if ! [[ $1 =~ ^[0-9]+$ ]]; then
  echo "Invalid input. Please provide the countdown time in seconds as a positive integer."
  exit 1
fi

countdown_time=$1
end_message=${2:-"The stream is now going live!"} # Default end message if not provided
countdown_message=${3:-"Stream starting in"} # Default countdown message if not provided
clear
while [ $countdown_time -gt 0 ]; do
  minutes=$((countdown_time / 60))
  seconds=$((countdown_time % 60))
  echo -ne '\n' # Move to a new line to avoid overwriting the final countdown message
  echo -ne "$countdown_message $minutes minute(s) and $seconds second(s)\r"
  echo -ne "\033[1A" # Move up one line
  sleep 1
  countdown_time=$((countdown_time - 1))
done
clear
echo "$end_message"
while [ true ] ; do
    read -t 3 -n 1
    if [ $? = 0 ] ; then
        break
    fi
done
