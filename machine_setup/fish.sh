#!/bin/bash
# This script is used to install fish shell

# order: 102

function fish_check() {
  if which fish > /dev/null; then
    return 0
  fi
  return -1
}

if [ "$1" == "check" ]; then
  fish_check
  exit $?
fi

if fish_check; then
  read -p "Fish shell is already installed. Do you want to reinstall it? (y/n) " answer
  if [[ "$answer" != "y" ]]; then
    exit 0
  fi
fi

sudo apt-add-repository ppa:fish-shell/release-3
sudo apt-get update
sudo apt-get install fish
