#!/bin/bash

# Filepath for the Docker proxy configuration
PROXY_CONF_DIR="/etc/systemd/system/docker.service.d"
PROXY_CONF_FILE="$PROXY_CONF_DIR/http-proxy.conf"

# Read kernel command line
CMDLINE=$(cat /proc/cmdline)

# Extract proxy parameters from the kernel command line
HTTP_PROXY=$(echo "$CMDLINE" | grep -oP '(?<=HTTP_PROXY=)[^ ]*')
HTTPS_PROXY=$(echo "$CMDLINE" | grep -oP '(?<=HTTPS_PROXY=)[^ ]*')
NO_PROXY=$(echo "$CMDLINE" | grep -oP '(?<=NO_PROXY=)[^ ]*')

# Create the directory if it doesn't exist
if [[ ! -d "$PROXY_CONF_DIR" ]]; then
    mkdir -p "$PROXY_CONF_DIR"
fi

# Initialize a flag to track if updates are needed
UPDATE_NEEDED=false

# Check if the file exists
if [[ -f "$PROXY_CONF_FILE" ]]; then
    # Read existing values from the file
    EXISTING_HTTP_PROXY=$(grep -oP '(?<=Environment="HTTP_PROXY=)[^"]*' "$PROXY_CONF_FILE")
    EXISTING_HTTPS_PROXY=$(grep -oP '(?<=Environment="HTTPS_PROXY=)[^"]*' "$PROXY_CONF_FILE")
    EXISTING_NO_PROXY=$(grep -oP '(?<=Environment="NO_PROXY=)[^"]*' "$PROXY_CONF_FILE")

    # Compare and update values if needed
    if [[ "$HTTP_PROXY" != "$EXISTING_HTTP_PROXY" && -n "$HTTP_PROXY" ]]; then
        UPDATE_NEEDED=true
    fi
    if [[ "$HTTPS_PROXY" != "$EXISTING_HTTPS_PROXY" && -n "$HTTPS_PROXY" ]]; then
        UPDATE_NEEDED=true
    fi
    if [[ "$NO_PROXY" != "$EXISTING_NO_PROXY" && -n "$NO_PROXY" ]]; then
        UPDATE_NEEDED=true
    fi
else
    # File does not exist, so we need to create it
    UPDATE_NEEDED=true
fi

# Write or update the file if needed
if [[ "$UPDATE_NEEDED" == true ]]; then
    {
        echo "[Service]"
        [[ -n "$HTTP_PROXY" ]] && echo "Environment=\"HTTP_PROXY=$HTTP_PROXY\""
        [[ -n "$HTTPS_PROXY" ]] && echo "Environment=\"HTTPS_PROXY=$HTTPS_PROXY\""
        [[ -n "$NO_PROXY" ]] && echo "Environment=\"NO_PROXY=$NO_PROXY\""
    } > "$PROXY_CONF_FILE"

    echo "Proxy configuration updated in $PROXY_CONF_FILE"
else
    echo "Proxy configuration is already up-to-date in $PROXY_CONF_FILE"
fi

# mount paths expected by tink/hookos docker containers
mkdir -p /var/run/docker
mkdir -p /var/run/images
mkdir -p /var/run/worker
mkdir -p /worker
ln -s /var/run/worker /worker

# start docker
systemctl daemon-reload
systemctl start docker

