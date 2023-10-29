#!/bin/bash

if ! command -v dialog &> /dev/null; then
  echo "Dialog is not installed. Installing Dialog..."
  sudo apt-get update
  sudo apt-get install -y dialog
fi

echo "Detecting USB drives..."

# Store all USB drives in a variable
usb_drives=$(lsblk -lno NAME,SIZE | grep sd.)

# Prepare the USB drives for the dialog command, ignoring lines that don't have 2 fields
usb_drives_for_dialog=$(echo "$usb_drives" | awk 'NF==2 {print $1, $2}')
usb_drives_for_dialog=${usb_drives_for_dialog//$'\n'/ }

# Echo the available USB drives
echo "Available USB drives:"
echo "$usb_drives"
echo -----
echo "$usb_drives_for_dialog"

# Use dialog to prompt for the USB drive
usb_device=$(dialog --stdout --menu "Please select the USB drive you want to mount:" 0 0 0 $usb_drives_for_dialog)

# Echo the selected USB drive
echo "You have selected: $usb_device"

# Validate input
if [[ ! "$usb_device" =~ ^sd[a-z][0-9]+ ]]; then
  echo "Invalid device name. Device name should be in the form sdb1, sdc2, etc."
  exit 1
fi

# Check if device is already mounted
if grep -qs "/dev/$usb_device " /proc/mounts; then
  echo "This USB drive is already mounted."
  exit 1
fi

# Check if device exists
if [ ! -b "/dev/$usb_device" ]; then
  echo "USB drive /dev/$usb_device does not exist. Please check the device name and try again."
  exit 1
fi

# Get the filesystem type
fs_type=$(sudo blkid -o value -s TYPE /dev/$usb_device)
if [ -z "$fs_type" ]; then
  echo "Could not determine the filesystem type of /dev/$usb_device. Please format the drive and try again."
  exit 1
fi

mount_point=$(dialog --stdout --dselect /mnt/ 0 0)

# Create mount point if it doesn't exist
if [ ! -d "$mount_point" ]; then
  sudo mkdir -p "$mount_point"
fi

echo "Enter the username for file ownership (leave blank for current user):"
read user_name
user_name=${user_name:-$(whoami)}

# Get the user UID
user_id=$(id -u $user_name)
if [ $? -ne 0 ]; then
  echo "User $user_name does not exist."
  exit 1
fi

# Get the group GID (assuming group name is the same as user name)
group_id=$(id -g $user_name)

# Add the USB drive to /etc/fstab
echo "/dev/$usb_device $mount_point auto defaults,uid=$user_id,gid=$group_id 0 0" | sudo tee -a /etc/fstab

# Mount all filesystems mentioned in fstab
sudo mount -a

if [ $? -eq 0 ]; then
  echo "USB drive /dev/$usb_device has been successfully mounted to $mount_point with ownership set to $user_name."
else
  echo "Failed to mount USB drive. Please check your input and try again."
fi
