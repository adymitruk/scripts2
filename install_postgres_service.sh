#!/bin/bash

# Prompt user for necessary information
read -p "Enter Atuin database username [atuin]: " ATUIN_DB_USERNAME
ATUIN_DB_USERNAME=${ATUIN_DB_USERNAME:-atuin}

read -sp "Enter Atuin database password: " ATUIN_DB_PASSWORD
echo ""

read -p "Enter database name [atuin]: " POSTGRES_DB
POSTGRES_DB=${POSTGRES_DB:-atuin}

# Create necessary directories
sudo mkdir -p /srv/atuin-server/config
if [[ $? -ne 0 ]]; then
    echo "Failed to create /srv/atuin-server/config directory. Exiting..."
    exit 1
fi

sudo mkdir -p /srv/atuin-server/database
if [[ $? -ne 0 ]]; then
    echo "Failed to create /srv/atuin-server/database directory. Exiting..."
    exit 1
fi

sudo chown $USER:$USER /srv/atuin-server -R
if [[ $? -ne 0 ]]; then
    echo "Failed to change ownership of /srv/atuin-server. Exiting..."
    exit 1
fi

# Create .env file
cat <<EOF > /srv/atuin-server/.env
ATUIN_DB_USERNAME=$ATUIN_DB_USERNAME
ATUIN_DB_PASSWORD=$ATUIN_DB_PASSWORD
POSTGRES_DB=$POSTGRES_DB
EOF
if [[ $? -ne 0 ]]; then
    echo "Failed to create .env file. Exiting..."
    exit 1
fi

# Create docker-compose.yml
cat <<EOF > /srv/atuin-server/docker-compose.yml
version: '3.5'
services:
  atuin:
    restart: always
    image: ghcr.io/atuinsh/atuin:main
    command: server start
    volumes:
      - "./config:/config"
    links:
      - postgresql:db
    ports:
      - 8888:8888
    environment:
      ATUIN_HOST: "0.0.0.0"
      ATUIN_OPEN_REGISTRATION: "true"
      ATUIN_DB_URI: postgres://$ATUIN_DB_USERNAME:$ATUIN_DB_PASSWORD@db/$POSTGRES_DB
  postgresql:
    image: postgres:14
    restart: unless-stopped
    volumes: # Don't remove permanent storage for index database files!
      - "./database:/var/lib/postgresql/data/"
    environment:
      POSTGRES_USER: $ATUIN_DB_USERNAME
      POSTGRES_PASSWORD: $ATUIN_DB_PASSWORD
      POSTGRES_DB: $POSTGRES_DB
EOF
if [[ $? -ne 0 ]]; then
    echo "Failed to create docker-compose.yml file. Exiting..."
    exit 1
fi

# Create systemd service file
sudo bash -c 'cat <<EOF > /etc/systemd/system/atuin.service
[Unit]
Description=Docker Compose Atuin Service
Requires=docker.service
After=docker.service

[Service]
WorkingDirectory=/srv/atuin-server
ExecStart=/usr/bin/docker-compose up
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0
Restart=on-failure
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF'
if [[ $? -ne 0 ]]; then
    echo "Failed to create systemd service file. Exiting..."
    exit 1
fi

# Reload systemd and start atuin service
sudo systemctl daemon-reload
if [[ $? -ne 0 ]]; then
    echo "Failed to reload systemd. Exiting..."
    exit 1
fi

sudo systemctl enable --now atuin
if [[ $? -ne 0 ]]; then
    echo "Failed to enable and start atuin service. Exiting..."
    exit 1
fi

# Output status
sudo systemctl status atuin
if [[ $? -ne 0 ]]; then
    echo "Failed to get status of atuin service. Exiting..."
    exit 1
fi
