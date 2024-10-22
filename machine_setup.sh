#!/bin/bash
# This script is used for machine setup

while true; do
  clear
  declare -A scripts
  index=0
  for script in machine_setup/*.sh; do
    scripts[$index]=$script
    script_name=$(basename $script)
    if bash "$script" check > /dev/null; then
      echo -e "$index. \e[32m\u2713\e[0m $script_name"
    else
      echo -e "$index. \e[30m\u25CF\e[0m $script_name"
    fi
    index=$((index+1))
  done
  read -p "Enter the number of the script you want to run, or 'q' to quit: " choice
  if [[ "$choice" == "q" ]]; then
    break
  fi
  if [[ -n "${scripts[$choice]}" ]]; then
    bash "${scripts[$choice]}"
  else
    echo "Invalid choice. Please try again."
  fi
  echo "Press any key to continue..."
  read -n 1 -s
done
