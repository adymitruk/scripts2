#!/bin/bash



username=$(whoami)

function check_symlink() {
  if [ -L "/usr/share/sddm/faces/$username.face.icon" ]; then
    return 0
  else
    return 1
  fi
}icon

if [ "$1" == "check" ]; then
  check_symlink
  exit $?
fi


check_symlink
if [ $? -eq 0 ]; then
  echo "Symlink already exists."
  exit 0
fi


sudo ln -s /home/$username/.profile_images/image.jpg /usr/share/sddm/faces/$username.face.icon
