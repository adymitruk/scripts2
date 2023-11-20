#!/bin/bash
if [[ $1 == "--debug" ]]; then
    DEBUG=true
else
    DEBUG=false
fi

TOTAL_LUKS_SLOTS=8

# Find the partitions that have luks, excluding ascii art
ENCRYPTED_PARTITIONS=($(lsblk --raw -f -o NAME,FSTYPE | grep 'crypto_LUKS' | awk '{print $1}'))
$DEBUG && echo "ENCRYPTED_PARTITIONS: ${ENCRYPTED_PARTITIONS[@]}"

# If there are more than one, allow the user to choose which one
if [ ${#ENCRYPTED_PARTITIONS[@]} -gt 1 ]; then
    echo "Multiple encrypted partitions found. Please select one:"
    select ENCRYPTED_PARTITION in "${ENCRYPTED_PARTITIONS[@]}"; do
        if [[ -n $ENCRYPTED_PARTITION ]]; then
            break
        else
            echo "Invalid selection"
        fi
    done
else
    ENCRYPTED_PARTITION=${ENCRYPTED_PARTITIONS[0]}
fi
$DEBUG && echo "ENCRYPTED_PARTITION: $ENCRYPTED_PARTITION"
echo "You have selected the partition: $ENCRYPTED_PARTITION"
read -p "Would you like to continue? (y/n) " CONTINUE
$DEBUG && echo "CONTINUE: $CONTINUE"
if [[ "${CONTINUE,,}" != "y" ]]; then
    echo "Exiting..."
    exit 1
fi

# Check if the partition exists and we have access to it
if [ ! -b "/dev/$ENCRYPTED_PARTITION" ]; then
    echo "Device $ENCRYPTED_PARTITION does not exist or access denied."
    exit 1
fi

# Get active slots
ACTIVE_SLOTS=($(sudo cryptsetup luksDump "/dev/$ENCRYPTED_PARTITION" | awk '/Keyslots:/,/Tokens:/{if($1 ~ /^[0-9]:/ && $2 == "luks2"){print substr($1, 1, length($1)-1)}}'))
$DEBUG && echo "ACTIVE_SLOTS: ${ACTIVE_SLOTS[@]}"


echo -n "Active Slots: "
for SLOT in ${ACTIVE_SLOTS[@]}; do
    echo -n "🔓$SLOT "
done
echo


read -p "Would you like to continue with identifying slot for a passphrase? (y/n) " CONTINUE
$DEBUG && echo "CONTINUE: $CONTINUE"
if [ "$CONTINUE" != "y" ]; then
    echo "Exiting..."
    exit 1
fi

while true; do
    read -rsp "Enter the passphrase to test: " PASSPHRASE
    echo
    # Test the passphrase against each active slot
    MATCHING_SLOTS=()
    for SLOT in $ACTIVE_SLOTS; do
        if echo "$PASSPHRASE" | sudo cryptsetup open --test-passphrase --key-slot "$SLOT" "/dev/$ENCRYPTED_PARTITION"; then
            MATCHING_SLOTS+=("$SLOT")
        fi
    done
$DEBUG && echo "MATCHING_SLOTS: ${MATCHING_SLOTS[@]}"
    echo -n "Slots: "
    for SLOT in $ACTIVE_SLOTS; do
        if [[ " ${MATCHING_SLOTS[@]} " =~ " ${SLOT} " ]]; then
            echo -n "🔓$SLOT "
        else
            echo -n "🔐$SLOT "
        fi
    done
    echo


    if [ ${#MATCHING_SLOTS[@]} -gt 1 ]; then
        echo "Unexpected: More than one slot matches the passphrase. Exiting..."
        exit 1
    elif [ ${#MATCHING_SLOTS[@]} -eq 0 ]; then
        read -p "Passphrase did not work with any slot. Would you like to try again? (y/n) " TRY_AGAIN
$DEBUG && echo "TRY_AGAIN: $TRY_AGAIN"
        if [ "$TRY_AGAIN" != "y" ]; then
            echo "Exiting..."
            exit 1
        fi
    else
        echo "🔑 Passphrase works with slot ${MATCHING_SLOTS[0]}. 🎉"
        break
    fi
done

TOTAL_SLOTS=({0..7})
REMAINING_SLOTS=()
for i in "${TOTAL_SLOTS[@]}"; do
    skip=
    for j in "${ACTIVE_SLOTS[@]}"; do
        [[ $i == $j ]] && { skip=1; break; }
    done
    [[ -n $skip ]] || REMAINING_SLOTS+=("$i")
done
echo "Remaining slots: ${REMAINING_SLOTS[@]}"
read -p "Enter the slot number where the new YubiKey will be put: " NEW_SLOT
$DEBUG && echo "NEW_SLOT: $NEW_SLOT"

