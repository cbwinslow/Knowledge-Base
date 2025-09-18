#!/bin/bash

# Setup home automation with Home Assistant, Zigbee2MQTT, etc.
echo "Setting up home automation stack..."

mkdir -p /opt/home-automation/{homeassistant,zigbee2mqtt,mosquitto}

# Create docker-compose.yml for home automation
cat > /opt/home-automation/docker-compose.yml << EOF
version: "3.8"

services:
  homeassistant:
    container_name: homeassistant
    image: ghcr.io/home-assistant/home-assistant:stable
    volumes:
      - ./homeassistant:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
    restart: unless-stopped
    privileged: true
    network_mode: host
    depends_on:
      - mosquitto

  zigbee2mqtt:
    container_name: zigbee2mqtt
    image: koenkk/zigbee2mqtt
    volumes:
      - ./zigbee2mqtt:/app/data
      - /run/udev:/run/udev:ro
    devices:
      - /dev/ttyACM0:/dev/ttyACM0
    restart: unless-stopped
    network_mode: host
    privileged: true
    depends_on:
      - mosquitto

  mosquitto:
    container_name: mosquitto
    image: eclipse-mosquitto:2
    user: "1883"
    ports:
      - 1883:1883
      - 9001:9001
    volumes:
      - ./mosquitto/data:/mosquitto/data
      - ./mosquitto/log:/mosquitto/log
      - ./mosquitto/config:/mosquitto/config
    restart: unless-stopped

  esphome:
    container_name: esphome
    image: esphome/esphome
    volumes:
      - ./esphome:/config
    ports:
      - 6052:6052
      - 6123:6123
    restart: unless-stopped
EOF

# Create Mosquitto config directory and files
mkdir -p /opt/home-automation/mosquitto/config
mkdir -p /opt/home-automation/mosquitto/data
mkdir -p /opt/home-automation/mosquitto/log

cat > /opt/home-automation/mosquitto/config/mosquitto.conf << EOF
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
listener 1883
allow_anonymous true
EOF

# Start home automation stack
cd /opt/home-automation
docker-compose up -d

echo "Home automation stack setup completed."