#!/bin/bash

# Reading environment variables
VPN_USERNAME="${PROTONVPN_USERNAME}"
VPN_PASSWORD="${PROTONVPN_PASSWORD}"

# Check if the credentials are provided
if [ -z "$VPN_USERNAME" ] || [ -z "$VPN_PASSWORD" ]; then
    echo "Proton VPN credentials are not set. Please set PROTONVPN_USERNAME and PROTONVPN_PASSWORD."
    exit 1
fi

# Non-interactive login to Proton VPN
echo $VPN_PASSWORD | protonvpn-cli login $VPN_USERNAME --stdin

# Connect to a Proton VPN server in Ireland
protonvpn-cli connect IE --cc

# Additional configuration if needed
