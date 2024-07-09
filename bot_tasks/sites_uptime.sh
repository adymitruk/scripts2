#!/bin/bash

# Check for debug parameter and set a variable if so
if [[ $1 == "--debug" ]]; then
  debug=true
  shift
else
  debug=false
fi

# Inline the values
file_contents="https://adaptechgroup.com/	We deliver solutions that power + scale the world's top companies.
https://eventmodeling.org/	Event Modeling is a method of describing systems using an example of how information has changed within them over time"

# Check if the last run log file exists
if [ ! -f "last_uptime_check.log" ]; then
  # If the log file does not exist, create one with the current time
  echo "$(date +%Y-%m-%d\ %H:%M:%S)" > "last_uptime_check.log"
  # Exit with 0
  exit 0
else
  # Get the last run time from the log file
  last_run=$(date -d "$(cat last_uptime_check.log)" +%s)
  # Get the current time
  now=$(date +"%s")
  # If the last run was less than 5 minutes ago, exit
  if [ $(($now - $last_run)) -lt 5 ]; then
    exit 0
  fi
fi

# Update the last run file
while IFS= read -r line
do
  # Skip empty lines
  if [[ -z $line ]]; then
    continue
  fi

  # Split the line into URL and expected content
  url=$(echo $line | cut -d' ' -f1)
  expected_content=$(echo $line | cut -d' ' -f2-)

  # If debug is set, echo the variables
  if [[ $debug == true ]]; then
    echo "URL: $url"
    echo "Expected content: $expected_content"
  fi

  # Use curl to fetch the content of the URL
  content=$(curl -s -H 'Cache-Control: no-cache' $url)

  # If debug is set, echo the fetched content
  if [[ $debug == true ]]; then
    echo "Fetched content: ${content:0:300}"
  fi

  # Check if the expected content is in the fetched content
  if [[ $content != *"$expected_content"* ]]; then
    echo "Site $url is down or does not contain the expected content."
  fi
done <<< "$file_contents"

# write the timestamp to the log file
echo "$(date +%Y-%m-%d\ %H:%M:%S)" > "last_uptime_check.log"



