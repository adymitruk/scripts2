#!/bin/bash

# Global Variables
SERVER_URL=""
USER_ID=""
AUTH_TOKEN=""
CHANNEL_ID=""
CRON_SCHEDULE=""
SCRIPT_TO_ADD=""

SCRIPT_DIR="/usr/local/sbin"
SCRIPTS_TO_RUN_DIR="$SCRIPT_DIR/scripts_to_run"
SCRIPT_NAME="rocket_chat_bot_script.sh"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

# Check for a debug parameter
DEBUG=0
for arg in "$@"
do
  if [ "$arg" == "--debug" ]
  then
    DEBUG=1
    echo DEBUG: debug set
  fi
done

# Check if script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Install curl if not present
if ! command -v curl &> /dev/null
then
    echo "curl could not be found, installing..."
    apt-get update
    apt-get install -y curl
    if [ $? -ne 0 ]; then
        echo "Failed to install curl" 1>&2
        exit 1
    fi
fi

# Create directory to contain scripts to run by the cron job
mkdir -p "$SCRIPTS_TO_RUN_DIR"
[ $DEBUG -eq 1 ] && echo DEBUG: scripts to run directory: "$SCRIPTS_TO_RUN_DIR"

# Create cron job
create_cron_job() {
    # Prompt for variable values
    read -p "Enter the server URL (include https:// etc): " SERVER_URL
    read -p "Enter the user ID: " USER_ID
    read -p "Enter the auth token: " AUTH_TOKEN
    read -p "Enter the channel ID: " CHANNEL_ID
    read -p "Enter the cron schedule (e.g., '0 0 * * *' for a nightly job, default is every 5 minutes): " CRON_SCHEDULE
    CRON_SCHEDULE=${CRON_SCHEDULE:-"*/5 * * * *"}
    
    cat << EOF > "$SCRIPT_PATH"
#!/bin/bash

for script in "$SCRIPT_DIR"/*
do
    SCRIPT_TO_RUN="\$script"
    OUTPUT=\$SCRIPT_TO_RUN
    if [ -n "\$OUTPUT" ]; then
        curl -s -X POST -H "Content-type:application/json" \
            -H "X-Auth-Token: $AUTH_TOKEN" \
            -H "X-User-Id: $USER_ID" \
            --data '{"channel": "$CHANNEL_ID", "text": "'"\$OUTPUT"'"}' \
            $SERVER_URL/api/v1/chat.postMessage
    fi
done
EOF

    echo "Here is the content of the new script:"
    cat "$SCRIPT_PATH"
    read -p "Do you want to continue with the installation? (y/n, default is n): " confirm
    if [ "$(echo "$confirm" | tr '[:upper:]' '[:lower:]' | xargs)" != "y" ]; then
        echo "Installation cancelled as per user request."
        exit 0
    fi


    chmod +x "$SCRIPT_PATH"

    (crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $SCRIPT_PATH") | crontab -
    if [ $? -ne 0 ]; then
        echo "Failed to create cron job" 1>&2
        exit 1
    fi
}

# Check if cron job already exists
if crontab -l | grep -q "$SCRIPT_PATH"; then
    echo "Cron job already installed. Here is the current cron job:"
    crontab -l | grep "$SCRIPT_PATH"
    echo "Here is the content of the current script:"
    cat "$SCRIPT_PATH"
    read -p "Do you want to overwrite the existing cron job? (y/n, default is n): " overwrite
    if [ "$(echo "$overwrite" | tr '[:upper:]' '[:lower:]' | xargs)" != "y" ]; then
        echo "Skipping cron job creation as per user request."
    else
        create_cron_job
    fi
else
    create_cron_job
fi

while true; do
    # List the script names from the scripts path with a number
    echo "Available scripts:"
    scripts=("$SCRIPT_DIR"/*)
    for i in "${!scripts[@]}"; do
        script_name=$(basename "${scripts[$i]}")
        # Check if the script is already installed and mark them with an asterisk
        if crontab -l | grep -q "$script_name"; then
            echo "$((i+1)). $script_name *"
        else
            echo "$((i+1)). $script_name"
        fi
    done

    # Prompt for the number of script to install
    read -p "Enter the number of the script to install (or hit Enter to not add any additional scripts): " script_number
    if [ -z "$script_number" ] || [ "$script_number" -lt 1 ] || [ "$script_number" -gt "${#scripts[@]}" ]; then
        echo "No additional scripts will be added."
        break
    else
        SCRIPT_TO_RUN="${scripts[$((script_number-1))]}"
    fi
    # Check if script already exists in the script directory
    if [ -f "$SCRIPT_PATH/$SCRIPT_TO_RUN" ]; then
        echo "The script already exists in the script directory. Here are the differences:"
        diff "$SCRIPT_TO_RUN" "$SCRIPT_PATH/$SCRIPT_TO_RUN"
        read -p "Do you want to overwrite the existing script? (y/n): " overwrite
        if [ "$(echo "$overwrite" | tr '[:upper:]' '[:lower:]' | xargs)" = "y" ]; then
            cp "$SCRIPT_TO_RUN" "$SCRIPT_PATH"
            if [ $? -ne 0 ]; then
                echo "Failed to copy script" 1>&2
                exit 1
            fi
        fi
    else
        cp "$SCRIPT_TO_RUN" "$SCRIPT_PATH"
        if [ $? -ne 0 ]; then
            echo "Failed to copy script" 1>&2
            exit 1
        fi
    fi
    chmod +x "$SCRIPT_PATH/$SCRIPT_TO_RUN"
    # Change the owner of the script to root
    chown root:root "$SCRIPT_PATH/$SCRIPT_TO_RUN"

    echo "The cron job will run the following scripts in the '$SCRIPT_PATH' directory:"
    ls -l "$SCRIPT_PATH"
    fi
done```
