#! /bin/bash

# Script to ship Nginx log files to Nextcloud
# Requires: nextcloud client, rsync

# Configuration
NGINX_LOG_DIR="/var/log/nginx"
NEXTCLOUD_DIR="$HOME/Nextcloud/nginx_logs"
DATE=$(date +%Y%m%d)
LOG_FILE="/var/log/nginx_ship.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# Check if required directories exist
if [ ! -d "$NGINX_LOG_DIR" ]; then
    log_message "Error: Nginx log directory not found at $NGINX_LOG_DIR"
    exit 1
fi

if [ ! -d "$NEXTCLOUD_DIR" ]; then
    log_message "Creating Nextcloud directory at $NEXTCLOUD_DIR"
    mkdir -p "$NEXTCLOUD_DIR"
fi

# Create dated directory in Nextcloud
DEST_DIR="$NEXTCLOUD_DIR/$DATE"
mkdir -p "$DEST_DIR"

# Copy log files
log_message "Starting log file transfer..."
rsync -av --progress "$NGINX_LOG_DIR"/*.log "$DEST_DIR"/ 2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    log_message "Log files successfully transferred to $DEST_DIR"
else
    log_message "Error: Failed to transfer log files"
    exit 1
fi

# Trigger Nextcloud sync
if command -v nextcloudcmd &> /dev/null; then
    log_message "Starting Nextcloud sync..."
    nextcloudcmd --non-interactive "$HOME/Nextcloud" https://your-nextcloud-server.com 2>> "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        log_message "Nextcloud sync completed successfully"
    else
        log_message "Error: Nextcloud sync failed"
        exit 1
    fi
else
    log_message "Warning: nextcloudcmd not found. Please install Nextcloud client"
    exit 1
fi 