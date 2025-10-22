# Docker Configurations

This directory stores Docker and container-related configurations.

## Structure

```
docker_configs/
├── compose/
│   ├── app1/
│   │   └── docker-compose.yml
│   └── app2/
│       └── docker-compose.yml
├── dockerfiles/
│   ├── Dockerfile.app1
│   └── Dockerfile.app2
├── volumes/
│   └── volume_configs.md
└── networks/
    └── network_configs.md
```

## Configuration Types

### Docker Compose Files

Store multi-container application configurations:

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    image: myapp:latest
    ports:
      - "8080:8080"
    environment:
      - ENV_VAR=value
    volumes:
      - ./data:/data
```

### Dockerfiles

Store container build configurations:

```dockerfile
# Dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y python3
COPY app.py /app/
CMD ["python3", "/app/app.py"]
```

### Volume Configurations

Document persistent data storage strategies.

### Network Configurations

Document container networking setups.

## Usage

### Saving Docker Configurations

Use the GitHub Actions workflow:

```bash
gh workflow run save-docker-config.yml -f config_name="myapp" -f config_type="compose" -f content="$(cat docker-compose.yml)"
```

Or manually add files:

```bash
mkdir -p docker_configs/compose/myapp
cp docker-compose.yml docker_configs/compose/myapp/
```

### Deploying Configurations

1. Clone this repository
2. Navigate to the configuration directory
3. Deploy using Docker:

```bash
cd docker_configs/compose/myapp
docker-compose up -d
```

## Security Notes

- Never commit secrets or sensitive credentials
- Use environment variables or Docker secrets
- Add `.env` files to `.gitignore`
- Use `.env.example` as templates
- Reference secrets documentation for secure practices

## Best Practices

1. **Version Control**: Keep configurations in sync with application versions
2. **Documentation**: Document each configuration's purpose and requirements
3. **Environment Variables**: Use env vars for configuration that changes between environments
4. **Resource Limits**: Always set memory and CPU limits
5. **Health Checks**: Include health check configurations
