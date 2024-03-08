#!/bin/bash

# Script to automatically update Discord Canary on Debian-based systems.
# Version: 1.0
# Author: Manuel Cebrian of NET.FR

# Usage:
# 1. Make this script executable with: chmod +x update-discord-deb.sh
# 2. Add a cron job to run this script daily by editing your crontab with: crontab -e
#    and adding the line: 0 0 * * * /path/to/update-discord-deb.sh
#    Replace /path/to/update-discord-deb.sh with the actual script path.

# Download URL and path
download_url="https://discord.com/api/download/canary?platform=linux&format=deb"
download_path="/tmp"

# Change to the download directory
cd "$download_path"

# Attempt to download the .deb package with the correct file name
wget_output=$(wget --content-disposition "$download_url" -N 2>&1)

# Extract the downloaded file name from wget output
latest_downloaded_file=$(echo "$wget_output" | grep -o -P '(?<=‘).*(?=’ has been saved)')

# Check if the file was downloaded
if [ -z "$latest_downloaded_file" ]; then
    echo "Failed to download the Discord package. Exiting."
    exit 1
fi

# Function to install Discord if a new version is detected
install_discord() {
    if sudo dpkg -i "$latest_downloaded_file"; then
        echo "Discord installed successfully."
        echo "$latest_downloaded_file" > "$download_path/last_installed_version.txt"
    else
        echo "Failed to install Discord. Please check for errors."
    fi
}

# Check for a new version and install if necessary
if [ -f "$download_path/last_installed_version.txt" ]; then
    last_installed_version=$(cat "$download_path/last_installed_version.txt")
    if [ "$latest_downloaded_file" != "$last_installed_version" ]; then
        echo "Detected a new version of Discord Canary."
        install_discord
    else
        echo "Current version of Discord Canary is up to date."
    fi
else
    echo "Installing Discord Canary for the first time."
    install_discord
fi
