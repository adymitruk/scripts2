#!/bin/bash
# This script is used to configure fish abbreviations
# Define abbreviations array
abbreviations=(
  "g git"
  "ga 'git add'"
  "gaa 'git add --all'"
  "gb 'git branch'"
  "gc 'git commit -v'"
  "gm 'git merge'"
  "gmn 'git merge --no-edit'"
  "gcm 'git commit -m'"
  "gco 'git checkout'"
  "gd 'git diff'"
  "gl 'git pull'"
  "gp 'git push'"
  "gs 'git status'"
  "glog 'git log --all --oneline --decorate --graph'"
  "apt 'sudo apt update && sudo apt upgrade -y'"
  "l 'ls -trAlh'"
  "rs 'rsync -av'"
)

missing_abbreviations=()
abbreviations_needing_updating=()

# The config_file variable needs to be defined before it's used
config_file=~/.config/fish/conf.d/abbreviations.fish

#check if the file exists
if [ -f "$config_file" ]; then
  for abbr in "${abbreviations[@]}"; do
      # Split the abbreviation into key and value
      key=$(echo "$abbr" | cut -d' ' -f1)
      value=$(echo "$abbr" | cut -d' ' -f2-)
      if ! grep -q "^abbr -a $key $value" "$config_file" > /dev/null; then
          echo "Abbreviation $key is missing or incorrect"
          if grep -q "^abbr -a $key" "$config_file"; then
              abbreviations_needing_updating+=("$abbr")
          else
              missing_abbreviations+=("$abbr")
          fi
      else
          echo "Abbreviation $key is set correctly"
      fi
  done
else
  # add all abbreviations to missing_abbreviations
  for abbr in "${abbreviations[@]}"; do
    missing_abbreviations+=("$abbr")
  done
fi

function fish_abbreviations_check() {
  # Check each abbreviation

  if [ ${#missing_abbreviations[@]} -gt 0 ] || [ ${#abbreviations_needing_updating[@]} -gt 0 ]; then
    echo "The following abbreviations are missing: ${missing_abbreviations[@]}"
    echo "The following abbreviations need to be updated: ${abbreviations_needing_updating[@]}"
    return 1
  fi
  
  echo "All abbreviations are set"
  return 0
}

if [ "$1" == "check" ]; then
  fish_abbreviations_check
  result=$?
  echo "got the result $result"
  exit $result
fi

# Fix the adding/updating sections to use the full abbreviation
for abbr in "${missing_abbreviations[@]}"; do
    echo "adding $abbr to $config_file"
    echo "abbr -a $abbr" >> "$config_file"
done

for abbr in "${abbreviations_needing_updating[@]}"; do
    key=$(echo "$abbr" | cut -d' ' -f1)
    echo "removing $key from $config_file"
    sed -i "/^abbr -a $key/d" "$config_file"
    echo "adding $abbr to $config_file"
    echo "abbr -a $abbr" >> "$config_file"
done

echo "Fish git abbreviations configured"
