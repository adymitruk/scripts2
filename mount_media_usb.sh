#!/bin/bash

echo "Detecting USB drives..."

# List all block devices with their size and mount point (if any)
lsblk -o NAME,SIZE,MOUNTPOINT | grep "sd."

echo "Please enter the device name of the USB drive you want to mount (e.g., sdb1):"
read usb_device

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

echo "Enter the mount point (e.g., /mnt/usb):"
read mount_point

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

# Mount the USB drive
sudo mount -o uid=$user_id,gid=$group_id /dev/$usb_device $mount_point

if [ $? -eq 0 ]; then
  echo "USB drive /dev/$usb_device has been successfully mounted to $mount_point with ownership set to $user_name."
else
  echo "Failed to mount USB drive. Please check your input and try again."
fi
