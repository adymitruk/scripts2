#!/bin/bash

# Function to install dialog if it's not installed
install_dialog() {
    if ! command -v dialog &> /dev/null; then
        echo "Dialog is not installed. Installing Dialog..."
        sudo apt-get update
        sudo apt-get install -y dialog
    fi
}

# Function to write the ISO to the destination with syncing every 256MB
write_iso() {
    local ISO_PATH="$1"
    local DEST_PATH="$2"
    local SIZE=$(stat -c %s "$ISO_PATH")
    local COUNT=0
    local BS=4M
    local SEEK=0
    
    (
    while [ $COUNT -lt $SIZE ]; do
        dd if="$ISO_PATH" bs=$BS count=64 skip=$SEEK | pv -s $((256 * 1024 * 1024)) -N dd | sudo dd of="$DEST_PATH" bs=$BS seek=$SEEK
        SEEK=$((SEEK + 64))
        COUNT=$(($COUNT + 256 * 1024 * 1024))
        sync
        echo $((COUNT * 100 / SIZE))
    done
    # If the ISO size is not a multiple of 256MB, write the remaining bytes
    if [ $COUNT -lt $SIZE ]; then
        dd if="$ISO_PATH" bs=$BS skip=$SEEK | pv -s $(($SIZE - $COUNT)) -N dd | sudo dd of="$DEST_PATH" bs=$BS seek=$SEEK
        sync
    fi
    echo 100
    ) | dialog --gauge "Writing ISO" 10 70 0
}

# Main script logic
install_dialog
ISO_PATH=$(dialog --stdout --title "use space bar to Select the ISO file" --fselect ~/Downloads/ 14 48)

if [ ! -f "$ISO_PATH" ]; then
    dialog --title "Error" --msgbox "Invalid file selected: $ISO_PATH. Exiting." 5 45
    exit 1
fi

DRIVE_LIST=$(sudo fdisk -l | grep -o '/dev/sd[a-z]' | sort -u)
DEST_PATH=$(dialog --stdout --title "Select Destination Drive" --menu "Please select the destination drive:" 15 55 4 ${DRIVE_LIST[@]})

if [ -z "$DEST_PATH" ]; then
    dialog --title "Error" --msgbox "No destination path provided. Exiting." 5 45
    exit 1
fi

if ! dialog --title "Confirmation" --yesno "Are you sure you want to write to $DEST_PATH? All data will be lost." 7 60; then
    dialog --title "Info" --msgbox "Operation cancelled." 5 30
    exit 1
fi

write_iso "$ISO_PATH" "$DEST_PATH"
dialog --title "Info" --msgbox "ISO writing process completed!" 5 30```
if dialog --title "Confirmation" --yesno "Do you want to verify the USB write operation?" 7 60; then
    ISO_SHA=$(sha256sum "$ISO_PATH" | awk '{ print $1 }')
    USB_SHA=$(sudo dd if="$DEST_PATH" bs=4M count=$(($SIZE / (4 * 1024 * 1024))) 2>/dev/null | sha256sum | awk '{ print $1 }')
    if [ "$ISO_SHA" != "$USB_SHA" ]; then
        dialog --title "Error" --msgbox "Verification failed. The ISO and USB contents do not match." 5 45
        exit 1
    else
        dialog --title "Info" --msgbox "Verification successful. The ISO and USB contents match." 5 45
    fi
fi

