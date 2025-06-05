#!/bin/bash

# Exit on any error
set -e

# Set Downloads directory
DOWNLOADS_DIR="$HOME/Downloads"
DISCORD_DIR="$DOWNLOADS_DIR/discord"

# Create discord directory in Downloads if it doesn't exist
mkdir -p "$DISCORD_DIR"

# Function to install dependencies
install_dependencies() {
    echo "Installing required dependencies..."
    sudo apt-get update
    sudo apt-get install -y libatomic1
}

# Function to get installed Discord version
get_installed_version() {
    if dpkg -l | grep -q "discord"; then
        dpkg -l | grep "discord" | awk '{print $3}'
    else
        echo "not_installed"
    fi
}

# Function to get latest version and filename from Discord's servers
get_latest_version_info() {
    # Get the actual filename from the download URL
    local download_url="https://discord.com/api/download?platform=linux&format=deb"
    local filename=$(wget --spider -S "$download_url" 2>&1 | grep "Content-Disposition:" | sed -n -e 's/^.*filename=//p' | tr -d '"')
    
    if [ -z "$filename" ]; then
        # Fallback if we can't get the filename from headers
        local temp_deb="$DISCORD_DIR/discord_temp.deb"
        wget -q -O "$temp_deb" "$download_url"
        local version=$(dpkg-deb -f "$temp_deb" Version)
        rm "$temp_deb"
        filename="discord-${version}.deb"
    fi
    
    # Extract version from filename
    local version=$(echo "$filename" | grep -oP '\d+\.\d+\.\d+')
    echo "$version|$filename"
}

# Function to install Discord
install_discord() {
    local version=$1
    local filename=$2
    local deb_path="$DISCORD_DIR/$filename"
    
    # Install dependencies first
    install_dependencies
    
    # Check if we already have the correct version downloaded
    if [ ! -f "$deb_path" ]; then
        echo "Downloading Discord version $version..."
        wget -O "$deb_path" "https://discord.com/api/download?platform=linux&format=deb"
    else
        echo "Using already downloaded Discord version $version"
    fi
    
    echo "Installing Discord..."
    sudo dpkg -i "$deb_path" || true  # Continue even if dpkg reports an error
    
    # Install any missing dependencies
    sudo apt-get install -f -y
    
    echo "Discord has been installed successfully!"
    echo "Installation file kept at: $deb_path"
}

# Check if Discord is already installed
INSTALLED_VERSION=$(get_installed_version)

# Get latest version info
echo "Checking latest Discord version..."
VERSION_INFO=$(get_latest_version_info)
LATEST_VERSION=$(echo "$VERSION_INFO" | cut -d'|' -f1)
LATEST_FILENAME=$(echo "$VERSION_INFO" | cut -d'|' -f2)

if [ "$INSTALLED_VERSION" != "not_installed" ]; then
    echo "Discord is currently installed (version: $INSTALLED_VERSION)"
    
    if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
        echo "You have the latest version of Discord installed."
        exit 0
    else
        echo "A newer version is available: $LATEST_VERSION"
        read -p "Would you like to upgrade? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_discord "$LATEST_VERSION" "$LATEST_FILENAME"
        else
            echo "Upgrade cancelled."
            exit 0
        fi
    fi
else
    echo "Latest Discord version available: $LATEST_VERSION"
    read -p "Would you like to install Discord $LATEST_VERSION? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_discord "$LATEST_VERSION" "$LATEST_FILENAME"
    else
        echo "Installation cancelled."
        exit 0
    fi
fi 