# CBW Tools Add-on (pgAdmin, Mongo Express, Neo4j Bloom)

This pack starts DB admin UIs with Docker.

## Install minimal deps + UFW
```bash
cd ~/cbw-ubuntu-setup/scripts
sudo bash install.sh
```

## Start the tools
```bash
cd ~/cbw-ubuntu-setup/docker/compose
docker compose --env-file ../env/tools.env -f tools.yml up -d
```

- pgAdmin: http://<server-ip>:5050
- Mongo Express: http://<server-ip>:8081
- Neo4j Bloom (optional, license required): http://<server-ip>:7475
