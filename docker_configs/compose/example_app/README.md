# Example Application Docker Compose

This is an example multi-container application setup with:
- Nginx web server
- Python application
- PostgreSQL database

## Services

### Web (Nginx)
- Port: 8080
- Serves static files from `./html`
- Health check configured

### App (Python)
- Python 3.11
- Connects to PostgreSQL database
- Environment variables configured

### Database (PostgreSQL)
- PostgreSQL 15
- Data persisted in volume
- Health check configured

## Usage

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## Environment Variables

Create a `.env` file (not committed) with:
```
POSTGRES_USER=your_user
POSTGRES_PASSWORD=your_password
POSTGRES_DB=your_db
```

## Network

All services communicate on the `app_network` bridge network.

## Volumes

- `db_data` - PostgreSQL data persistence
- `./html` - Web static files
- `./app` - Application code
