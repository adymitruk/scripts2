#!/bin/bash

# Prompt for the folder you want to share
read -p "Enter the full path of the folder you want to share: " share_folder

# Prompt for the share name
read -p "Enter a name for the Samba share: " share_name

# Install Samba
sudo apt-get update
sudo apt-get install samba

# Create a new group for shared access
read -p "Enter a name for the new group: " group_name
sudo groupadd $group_name

# Add the main user and the Samba user to the new group
sudo usermod -aG $group_name $(whoami)

# Change the group ownership of the share folder to the new group
sudo chgrp -R $group_name $share_folder

# Give the group read, write, and execute permissions on the share folder
sudo chmod -R 770 $share_folder

# Create the Samba share configuration
echo "[$share_name]" | sudo tee -a /etc/samba/smb.conf
echo "path = $share_folder" | sudo tee -a /etc/samba/smb.conf
echo "read only = no" | sudo tee -a /etc/samba/smb.conf
echo "guest ok = yes" | sudo tee -a /etc/samba/smb.conf

# Prompt for your Samba username
read -p "Enter your Samba username: " smb_username

# Add the Samba user to the new group
sudo usermod -aG $group_name $smb_username

# Set the Samba password for your user
sudo smbpasswd -a $smb_username

# Check if there is a mount in /etc/fstab that points to the shared folder
if grep -q "$share_folder" /etc/fstab; then
  # If there is, make sure the samba user can access it too
  smb_user_id=$(id -u $smb_username)
  smb_group_id=$(id -g $smb_username)
  sudo sed -i "s|$share_folder.*|$share_folder auto defaults,uid=$smb_user_id,gid=$smb_group_id 0 0|" /etc/fstab
  # Remount all filesystems mentioned in fstab
  sudo mount -a

  if [ $? -eq 0 ]; then
    echo "Shared folder $share_folder has been successfully remounted with Samba user $smb_username."
  else
    echo "Failed to remount shared folder. Please check your input and try again."
  fi
else
  echo "No mount found in /etc/fstab that points to the shared folder."
fi


# Restart Samba
sudo service smbd restart

echo "Samba share configured successfully!"
