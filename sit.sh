#!/bin/bash

# Debug flag (set DEBUG=true to enable debugging)
DEBUG=""

# Ensure necessary tools are installed
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required but it's not installed. Installing..."; sudo apt-get install jq -y; }
command -v curl >/dev/null 2>&1 || { echo >&2 "curl is required but it's not installed. Installing..."; sudo apt-get install curl -y; }
command -v pup >/dev/null 2>&1 || {
  wget https://github.com/ericchiang/pup/releases/download/v0.4.0/pup_v0.4.0_linux_amd64.zip;
  unzip pup_v0.4.0_linux_amd64.zip;
  sudo mv pup /usr/local/bin/;
}

# Function to get the IP address, compatible with both Linux and macOS
get_ip_address() {
  if command -v ip >/dev/null 2>&1; then
    ip=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n 1)
  else
    ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1)
  fi
  echo "$ip"
}

# Function to fetch latest news headlines from CNN using awk
fetch_news_headlines() {
  echo "Latest World News Headlines:"
  local headlines=$(curl -sL "https://lite.cnn.com")

  # Parsing headlines using awk, trimming whitespace, and adding prefix
  local parsed_headlines=$(echo "$headlines" | awk '/<li class="card--lite">/,/<\/li>/{gsub(/<[^>]*>/, ""); if (NF) print " -" $0}' | sed 's/^[ \t]*//;s/[ \t]*$//' | head -5)

  if [[ -n "$DEBUG" ]]; then
    echo "$headlines"
  else
    echo "$parsed_headlines"
  fi
}

# Function to get current system information with the day included
get_system_info() {
  echo "$(date '+%A %B %Y')"
  local hour=$(date '+%H')
  local emoji
  if [ "$hour" -ge 18 ] || [ "$hour" -lt 6 ]; then
    emoji="🌙"
  else
    emoji="☀️"
  fi
  echo "Current Time: $(date '+%A %l:%M %p') $emoji"
  local ip=$(get_ip_address)
  echo "Current IP Address: $ip"
  echo "Current Timezone: $(date +%Z)"
}

# Function to get geolocation information
get_geolocation() {
  local ip=$1
  local geo_info=$(curl -s "https://ipinfo.io/$ip")
  echo " $(echo $geo_info | jq -r '.city'), $(echo $geo_info | jq -r '.country')"
}

# Function to get weather information
get_weather_info() {
  local city=$1
  local weather_info=$(curl -s "https://wttr.in/$city?format=3")
  echo " $weather_info"
}

# Main function
sit() {
  if [ -n "$SSH_CLIENT" ]; then
    local ssh_ip=$(echo $SSH_CLIENT | awk '{ print $1 }')

    echo -n "My Location:"
    get_geolocation "$ssh_ip"
    echo -n "My Weather:"
    local ssh_city=$(curl -s "https://ipinfo.io/$ssh_ip" | jq -r '.city')
    get_weather_info "$ssh_city"
    echo "My Time:"
    # Logic for local time goes here

    echo -n "Destination:"
    local ip=$(get_ip_address)
    get_geolocation "$ip"
    echo -n "Destination Weather:"
    local city=$(curl -s "https://ipinfo.io/$ip" | jq -r '.city')
    get_weather_info "$city"
    echo -n "Destination Time:"
    get_system_info

  else
    get_system_info
    local ip=$(get_ip_address)
    get_geolocation "$ip"
    local city=$(curl -s "https://ipinfo.io/$ip" | jq -r '.city')
    get_weather_info "$city"
  fi

  fetch_news_headlines
}

# Run the script
sit
