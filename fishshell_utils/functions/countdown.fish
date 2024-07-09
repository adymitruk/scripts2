#!/usr/bin/env fish

# This script will count down from the argument provided
# it will be used to show time and countdown by the second
# for a twitch stream that will begin then.
# when the countdown reaches zero, another message will show 
# that the stream is going live

function print_help
  echo "Usage: $argv[0] <countdown_time_in_seconds> [end_message] [countdown_message]"
  echo
  echo "Arguments:"
  echo "  countdown_time_in_seconds  The countdown time in seconds (required)"
  echo "  end_message                The message to display when the countdown reaches zero (optional)"
  echo "  countdown_message          The message to display during the countdown (optional)"
  echo
  echo "Example:"
  echo "  $argv[0] 60 'The stream is now going live!' 'Stream starting in'"
end

function countdown
  if test "$argv[1]" = "--help"
    print_help
    return 0
  end

  if test (count $argv) -lt 1
    echo "No arguments supplied. Please provide the countdown time in seconds."
    return 1
  end

  # Ensure the input is a valid number
  if not string match -r '^[0-9]+$' -- $argv[1]
    echo "Invalid input. Please provide the countdown time in seconds as a positive integer."
    return 1
  end

  set countdown_time $argv[1]
  if test -n "$argv[2]"; set end_message $argv[2]; else; set end_message 'The stream is now going live!'; end
  if test -n "$argv[3]"; set countdown_message $argv[3]; else; set countdown_message 'Stream starting in'; end

  set start_time (date +%s)
  set end_time (math "$start_time + $countdown_time")
  clear
  while test (date +%s) -lt $end_time
    set now (date +%s)
    set remaining_time (math $end_time - $now)
    set minutes (math -s0 $remaining_time / 60)
    set seconds (math $remaining_time % 60)
    echo -ne '\n' # Move to a new line to avoid overwriting the final countdown message
    echo -ne "$countdown_message $minutes minute(s) and $seconds second(s)\r"
    echo -ne "\033[1A" # Move up one line
    sleep 1
  end
  clear
  while true
    read -P "$end_message Press any key to continue..." -t 3 -n 1
    if test $status = 0
      break
    end
  end
end
