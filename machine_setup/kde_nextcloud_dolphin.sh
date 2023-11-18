#!/bin/bash
# This script is used to setup KDE Nextcloud Dolphin integration

function kde_nextcloud_dolphin_check() {
  if dpkg -l | grep -q "dolphin-nextcloud"; then
    return 0
  else
    return 1
  fi
}

if [ "$1" == "check" ]; then
  kde_nextcloud_dolphin_check
  exit $?
fi

if kde_nextcloud_dolphin_check; then
  echo "Dolphin Nextcloud integration is already installed."
else
  sudo add-apt-repository ppa:nextcloud-devs/client
  sudo apt update
  sudo apt install dolphin-nextcloud
fi


