#!/bin/bash

function fisher_check() {
    if fish -c "type fisher >/dev/null 2>&1"; then
        return 0
    else
        return 1
    fi
}
if [ "$1" == "check" ]; then
    fisher_check
    exit $?
fi

# Define the URL for the Fisher installation script
FISHER_URL="https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish"

if fisher_check; then
    echo "Fisher is already installed from $FISHER_URL"
    exit 0
fi

# check if curl is installed
if ! command -v curl >/dev/null 2>&1; then
    echo "curl is not installed. Please install it first."
    exit 1
fi

echo "Installing Fisher from $FISHER_URL"
fish -c "curl -sL $FISHER_URL | source && fisher install jorgebucaran/fisher"
