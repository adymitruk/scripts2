#!/bin/bash
# This script is used for machine setup
declare -A menu_items
while true; do
  clear
  declare -A scripts
  index=0
  for script in machine_setup/*.sh; do
    scripts[$index]=$script
    script_name=$(basename $script)
    if bash "$script" check; then
      menu_items[$index]="$index. \e[32m\u2713\e[0m $script_name"
    else
      menu_items[$index]="$index. \e[30m\u25CF\e[0m $script_name"
    fi
    index=$((index+1))
  done
  echo "done checking scripts. press enter to continue"
  read -p ""
  clear
  echo "Select an option:"
  for item in "${menu_items[@]}"; do
    echo -e "$item"
  done
  read -p "Enter the number of the script you want to run, or 'q' to quit: " choice
  if [[ "$choice" == "q" ]]; then
    break
  fi
  if [[ -n "${scripts[$choice]}" ]]; then
    bash "${scripts[$choice]}"
    echo "Press Enter to continue"
    read -p ""
  else
    echo "Invalid choice. Please try again."
  fi
done
