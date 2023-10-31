#!/bin/bash

# Check for debug parameter and set a variable if so
if [[ $1 == "--debug" ]]; then
  debug=true
  shift
else
  debug=false
fi

# Get the file name from the command line
if [[ -z $1 ]]; then
  echo "Error: No file specified."
  exit 1
else
  file_name=$1
fi

# Check if the last run log file exists
if [ -f "last_run.log" ]; then
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
touch "last_run.log"

# Check if file exists
if [ ! -f "$file_name" ]; then
  echo "File not found!"
  exit 1
fi

# Read the file line by line
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
    echo "Fetched content: $content"
  fi

  # Check if the expected content is in the fetched content
  if [[ $content != *"$expected_content"* ]]; then
    echo "Site $url is down or does not contain the expected content."
  fi
done < "$file_name"

# write the timestamp to the log file
echo "$(date +%Y-%m-%d\ %H:%M:%S)" > "last_uptime_check.log"



