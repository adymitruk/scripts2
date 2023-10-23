#!/bin/bash
if [ "$1" == "--rebuild" ]; then
    REBUILD=true
else
    REBUILD=false
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found! Installing..."
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
else
    echo "Docker is already installed!"
fi

# Set cgroups for Docker to limit resources
CGROUP_PATH="/sys/fs/cgroup/cpu/docker"
if [ ! -d "$CGROUP_PATH" ]; then
    sudo mkdir -p "$CGROUP_PATH"
    echo $(( $(nproc) * 1024 / 10 )) | sudo tee "$CGROUP_PATH/cpu.shares"
    echo $(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 10 )) | sudo tee /sys/fs/cgroup/memory/docker/memory.limit_in_bytes
fi

# Check if postgres_container is already running or exists
if sudo docker ps -a | grep postgres_container &> /dev/null; then
    echo "Stopping and removing existing postgres_container..."
    sudo docker stop postgres_container
    sudo docker rm postgres_container
elif sudo docker ps -a -f status=exited | grep postgres_container &> /dev/null; then
    echo "Removing exited postgres_container..."
    sudo docker rm postgres_container
fi

# Run PostgreSQL inside the custom Docker container
read -sp "Enter PostgreSQL password: " PG_PASSWORD
# Check if the Docker image for PostgreSQL on Ubuntu 22.04 exists and build it if not or if REBUILD is true
if [ "$REBUILD" = true ] || ! sudo docker images | grep postgres_16 &> /dev/null; then
    # Create a Dockerfile to install PostgreSQL on Ubuntu 22.04
    echo "FROM postgres:16

USER postgres

ARG PG_PASSWORD_ARG=chanegme
ENV POSTGRES_PASSWORD=\$PG_PASSWORD_ARG
RUN echo \$PG_PASSWORD
RUN chmod 0700 /var/lib/postgresql/data &&\
    initdb /var/lib/postgresql/data &&\
    echo \"host all  all    0.0.0.0/0  md5\" >> /var/lib/postgresql/data/pg_hba.conf &&\
    echo \"listen_addresses='*'\" >> /var/lib/postgresql/data/postgresql.conf &&\
    pg_ctl start &&\
    psql -U postgres -tc \"SELECT 1 FROM pg_database WHERE datname = 'main'\" | grep -q 1 || psql -U postgres -c \"CREATE DATABASE main\" &&\
    psql -c \"ALTER USER postgres WITH ENCRYPTED PASSWORD '\$POSTGRES_PASSWORD';\"

EXPOSE 5432
" > Dockerfile

    # Build the Docker image
    sudo docker build --build-arg PG_PASSWORD_ARG=$PG_PASSWORD -t postgres_16 .
    rm Dockerfile
fi

# Check if a Docker container named postgres_container exists
if sudo docker ps -a --format '{{.Names}}' | grep -w postgres_container &> /dev/null; then
    # If it exists, stop and remove it
    echo "Stopping and removing existing postgres_container..."
    sudo docker stop postgres_container
    sudo docker rm postgres_container
fi

# Check if the systemd service for the Docker container exists
if [ -f /etc/systemd/system/docker-postgresql.service ]; then
    sudo systemctl stop docker-postgresql.service
    sudo systemctl disable docker-postgresql.service
    sudo rm /etc/systemd/system/docker-postgresql.service
fi

# Create the systemd service to make the Docker container always run on startup
echo "[Unit]
Description=PostgreSQL Docker Container

[Service]
Restart=always
ExecStartPre=/usr/bin/docker rm -f postgres_container
ExecStart=/usr/bin/docker run --name postgres_container -p 5432:5432 postgres_16
ExecStop=/usr/bin/docker stop -t 2 postgres_container
[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/docker-postgresql.service

sudo systemctl daemon-reload
sudo systemctl enable docker-postgresql.service
sudo systemctl start docker-postgresql.service

read -p "Enter username for SSH jumpstation: " SSH_USER
read -p "Enter address for SSH jumpstation: " SSH_ADDRESS

SERVICE_NAME="ssh_jumpstation_tunnel.service"

if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "Existing SSH jumpstation service found! Removing..."
    sudo systemctl stop "$SERVICE_NAME"
    sudo systemctl disable "$SERVICE_NAME"
    sudo rm "/etc/systemd/system/$SERVICE_NAME"
fi

echo "[Unit]
Description=SSH tunnel to jumpstation for PostgreSQL
After=network.target

[Service]
User=$SSH_USER
ExecStart=/usr/bin/ssh -NT -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -R 5432:localhost:5432 $SSH_USER@$SSH_ADDRESS
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target" | sudo tee "/etc/systemd/system/$SERVICE_NAME"

sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

# Print the message on how to connect through jumpstation
echo "To connect to PostgreSQL through the jumpstation from a third computer, use the following command:"
echo "ssh -L 5432:localhost:5432 $SSH_USER@$SSH_ADDRESS"

