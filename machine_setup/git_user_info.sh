#!/bin/bash
# This script is used to configure git user information

# order: 100

function git_user_info_check() {
  if git config --global user.name &> /dev/null && git config --global user.email &> /dev/null; then
    return 0
  fi
  return 1
}

if [ "$1" == "check" ]; then
  git_user_info_check
  exit $?
fi


if git_user_info_check; then
  read -p "Would you like to reconfigure? (y/n): " reconfigure
  if [[ "$reconfigure" != "y" ]]; then
    exit 0
  fi
fi


echo "Configuring Git User Name and Email"
read -p "Enter Your Name: " name
read -p "Enter Your Email: " email
git config --global user.name "$name"
git config --global user.email "$email"
echo "Git Configuration:"
git config --global --list



