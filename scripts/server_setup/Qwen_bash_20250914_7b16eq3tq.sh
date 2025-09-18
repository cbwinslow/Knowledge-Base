#!/bin/bash

# Setup MCP (Minecraft Pocket Edition) servers
echo "Setting up MCP servers..."

mkdir -p /opt/mcp-servers/{bedrock,java}
mkdir -p /opt/mcp-servers/scripts

# Install required packages
apt update
apt install -y openjdk-17-jre-headless

# Create Bedrock server docker-compose.yml
cat > /opt/mcp-servers/bedrock/docker-compose.yml << EOF
version: "3.8"

services:
  bedrock-server:
    image: itzg/minecraft-bedrock-server
    container_name: bedrock-server
    environment:
      EULA: "TRUE"
      GAMEMODE: survival
      DIFFICULTY: normal
      LEVEL_TYPE: DEFAULT
      SERVER_NAME: "Proxmox Bedrock Server"
      SERVER_PORT: 19132
      LEVEL_NAME: "BedrockWorld"
      ONLINE_MODE: "true"
      MAX_PLAYERS: 20
      WHITE_LIST: "false"
      ALLOW_CHEATS: "false"
      PVP: "true"
      LEVEL_SEED: ""
    volumes:
      - bedrock_data:/data
    ports:
      - "19132:19132/udp"
    restart: unless-stopped
    networks:
      - mcp-net

volumes:
  bedrock_data:

networks:
  mcp-net:
    driver: bridge
EOF

# Create Java server docker-compose.yml
cat > /opt/mcp-servers/java/docker-compose.yml << EOF
version: "3.8"

services:
  java-server:
    image: itzg/minecraft-server
    container_name: java-server
    environment:
      EULA: "TRUE"
      TYPE: PAPER
      VERSION: "1.20.1"
      DIFFICULTY: normal
      LEVEL_TYPE: DEFAULT
      SERVER_NAME: "Proxmox Java Server"
      SERVER_PORT: 25565
      LEVEL: "JavaWorld"
      ONLINE_MODE: "TRUE"
      MAX_PLAYERS: 20
      MOTD: "Welcome to Proxmox Minecraft Server!"
      ENABLE_RCON: "true"
      RCON_PASSWORD: "minecraft"
      RCON_PORT: 25575
      JVM_OPTS: "-Xmx2G -Xms1G"
    volumes:
      - java_data:/data
    ports:
      - "25565:25565"
      - "25575:25575"
    restart: unless-stopped
    networks:
      - mcp-net

volumes:
  java_data:

networks:
  mcp-net:
    driver: bridge
EOF

# Create MCP management script
cat > /opt/mcp-servers/scripts/mcp-manager.sh << 'EOF'
#!/bin/bash

# MCP Server Management Script

ACTION=$1
SERVER_TYPE=$2

case $ACTION in
    start)
        if [ "$SERVER_TYPE" = "bedrock" ]; then
            cd /opt/mcp-servers/bedrock && docker-compose up -d
            echo "Bedrock server started"
        elif [ "$SERVER_TYPE" = "java" ]; then
            cd /opt/mcp-servers/java && docker-compose up -d
            echo "Java server started"
        else
            echo "Usage: $0 start [bedrock|java]"
        fi
        ;;
    stop)
        if [ "$SERVER_TYPE" = "bedrock" ]; then
            cd /opt/mcp-servers/bedrock && docker-compose down
            echo "Bedrock server stopped"
        elif [ "$SERVER_TYPE" = "java" ]; then
            cd /opt/mcp-servers/java && docker-compose down
            echo "Java server stopped"
        else
            echo "Usage: $0 stop [bedrock|java]"
        fi
        ;;
    status)
        docker ps | grep -E "(bedrock|java)-server"
        ;;
    backup)
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        if [ "$SERVER_TYPE" = "bedrock" ]; then
            docker exec bedrock-server tar czf /tmp/bedrock-backup-$TIMESTAMP.tar.gz -C /data .
            docker cp bedrock-server:/tmp/bedrock-backup-$TIMESTAMP.tar.gz /opt/backups/
            echo "Bedrock server backup created: /opt/backups/bedrock-backup-$TIMESTAMP.tar.gz"
        elif [ "$SERVER_TYPE" = "java" ]; then
            docker exec java-server tar czf /tmp/java-backup-$TIMESTAMP.tar.gz -C /data .
            docker cp java-server:/tmp/java-backup-$TIMESTAMP.tar.gz /opt/backups/
            echo "Java server backup created: /opt/backups/java-backup-$TIMESTAMP.tar.gz"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status|backup} [bedrock|java]"
        ;;
esac
EOF

chmod +x /opt/mcp-servers/scripts/mcp-manager.sh

# Create cron job for automatic backups
cat > /etc/cron.daily/mcp-backup << 'EOF'
#!/bin/bash
# Daily MCP server backups

/opt/mcp-servers/scripts/mcp-manager.sh backup bedrock
/opt/mcp-servers/scripts/mcp-manager.sh backup java
EOF

chmod +x /etc/cron.daily/mcp-backup

# Start MCP servers
cd /opt/mcp-servers/bedrock
docker-compose up -d

cd /opt/mcp-servers/java
docker-compose up -d

echo "MCP servers setup completed."