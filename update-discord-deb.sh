#!/bin/bash

# Script to automatically update Discord Canary on Debian-based systems.
# Version: 1.0
# Author: Manuel Cebrian of NET.FR

# Usage instructions and cron job setup are embedded within this script.
# Add a cron job to execute this script daily by editing your crontab:
# crontab -e
# Add the line: 0 0 * * * /path/to/update-discord-deb.sh

# Download URL and path
download_url="https://discord.com/api/download/canary?platform=linux&format=deb"
download_path="/tmp"

# Filename pattern to match the downloaded file
pattern="discord-canary-*.deb"

# Move to the download path
cd "$download_path"

# Download the latest Discord Canary version
wget --content-disposition "$download_url" -N

# Find the most recently downloaded .deb file
latest_downloaded_file=$(ls -Art $pattern | tail -n 1)

if [[ -z "$latest_downloaded_file" ]]; then
    echo "Failed to download the Discord package. Exiting."
    exit 1
fi

# Record of the last installed version
last_installed_version_file="$download_path/last_installed_version.txt"

install_discord() {
    echo "Installing Discord Canary: $latest_downloaded_file"
    if sudo dpkg -i "$latest_downloaded_file"; then
        echo "$latest_downloaded_file" > "$last_installed_version_file"
        echo "Installation successful."
    else
        echo "Installation failed."
        exit 1
    fi
}

# Check for a new version and install if necessary
if [ -f "$last_installed_version_file" ]; then
    last_installed_version=$(cat "$last_installed_version_file")
    if [ "$latest_downloaded_file" != "$last_installed_version" ]; then
        install_discord
    else
        echo "The latest version of Discord Canary is already installed."
    fi
else
    install_discord
fi
