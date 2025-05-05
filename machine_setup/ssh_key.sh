#!/bin/bash

function check_if_exists {
    # Check if SSH key already exists
    if [ -f ~/.ssh/id_rsa ]; then
        echo "SSH key already exists."
        return 0
    else
        return 1
    fi
}

if [ "$1" == "check" ]; then
    check_if_exists
    exit $?
fi

if check_if_exists; then
    echo "SSH key already exists."
    echo "Your public key is:"
    cat ~/.ssh/id_rsa.pub
    read -p "Do you want to continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
fi

# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate new SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Set correct permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

echo "SSH key has been generated successfully."
echo "Your public key is:"
cat ~/.ssh/id_rsa.pub 