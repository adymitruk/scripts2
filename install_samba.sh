#!/bin/bash

# Prompt for the folder you want to share
read -p "Enter the full path of the folder you want to share: " share_folder

# Prompt for the share name
read -p "Enter a name for the Samba share: " share_name

# Install Samba
sudo apt-get update
sudo apt-get install samba

# Create the Samba share configuration
echo "[$share_name]" | sudo tee -a /etc/samba/smb.conf
echo "path = $share_folder" | sudo tee -a /etc/samba/smb.conf
echo "read only = no" | sudo tee -a /etc/samba/smb.conf
echo "guest ok = yes" | sudo tee -a /etc/samba/smb.conf

# Prompt for your Samba username
read -p "Enter your Samba username: " smb_username

# Set the Samba password for your user
sudo smbpasswd -a $smb_username

# Restart Samba
sudo service smbd restart

echo "Samba share configured successfully!"
