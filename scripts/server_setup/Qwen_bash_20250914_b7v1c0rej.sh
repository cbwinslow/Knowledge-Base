#!/bin/bash

# Create media stack with Plex, Sonarr, Radarr, etc.
echo "Setting up media stack..."

# Create media directories
mkdir -p /opt/media/{tv,movies,downloads,torrents}
mkdir -p /opt/media/config/{plex,sonarr,radarr,bazarr,transmission,jackett}

# Create docker-compose.yml for media stack
cat > /opt/media-stack/docker-compose.yml << EOF
version: "3.8"

services:
  plex:
    image: linuxserver/plex
    container_name: plex
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - VERSION=docker
    volumes:
      - /opt/media/config/plex:/config
      - /opt/media/tv:/tv
      - /opt/media/movies:/movies
    ports:
      - 32400:32400
    restart: unless-stopped
    network_mode: host

  sonarr:
    image: linuxserver/sonarr
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - /opt/media/config/sonarr:/config
      - /opt/media/tv:/tv
      - /opt/media/downloads:/downloads
    ports:
      - 8989:8989
    restart: unless-stopped

  radarr:
    image: linuxserver/radarr
    container_name: radarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - /opt/media/config/radarr:/config
      - /opt/media/movies:/movies
      - /opt/media/downloads:/downloads
    ports:
      - 7878:7878
    restart: unless-stopped

  bazarr:
    image: linuxserver/bazarr
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - /opt/media/config/bazarr:/config
      - /opt/media/movies:/movies
      - /opt/media/tv:/tv
    ports:
      - 6767:6767
    restart: unless-stopped

  transmission:
    image: linuxserver/transmission
    container_name: transmission
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - /opt/media/config/transmission:/config
      - /opt/media/downloads:/downloads
      - /opt/media/torrents:/watch
    ports:
      - 9091:9091
      - 51413:51413
      - 51413:51413/udp
    restart: unless-stopped

  jackett:
    image: linuxserver/jackett
    container_name: jackett
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - /opt/media/config/jackett:/config
      - /opt/media/downloads:/downloads
    ports:
      - 9117:9117
    restart: unless-stopped

  flaresolverr:
    image: ghcr.io/flaresolverr/flaresolverr:latest
    container_name: flaresolverr
    environment:
      - LOG_LEVEL=info
      - LOG_HTML=false
      - CAPTCHA_SOLVER=none
      - TZ=Europe/London
    ports:
      - 8191:8191
    restart: unless-stopped
EOF

# Start the media stack
cd /opt/media-stack
docker-compose up -d

echo "Media stack setup completed."