#!/bin/bash

# Setup database stack with PostgreSQL and Supabase
echo "Setting up database stack..."

mkdir -p /opt/database/{postgres,supabase}

# Create PostgreSQL docker-compose.yml
cat > /opt/database/postgres/docker-compose.yml << EOF
version: "3.8"

services:
  postgres:
    image: postgres:15
    container_name: postgres
    environment:
      POSTGRES_DB: maindb
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-securepassword123}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"
    restart: unless-stopped
    networks:
      - database-net

  pgadmin:
    image: dpage/pgadmin4
    container_name: pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@localhost.com
      PGADMIN_DEFAULT_PASSWORD: admin
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    ports:
      - "5050:80"
    restart: unless-stopped
    depends_on:
      - postgres
    networks:
      - database-net

volumes:
  postgres_data:
  pgadmin_data:

networks:
  database-net:
    driver: bridge
EOF

# Create Supabase docker-compose.yml (simplified version)
cat > /opt/database/supabase/docker-compose.yml << EOF
version: "3.8"

services:
  supabase-db:
    image: supabase/postgres:15.1.0.117
    container_name: supabase-db
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: postgres
      JWT_SECRET: ${JWT_SECRET:-super-secret-jwt-token-with-at-least-32-characters-long}
      ANON_KEY: ${ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0}
      SERVICE_ROLE_KEY: ${SERVICE_ROLE_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU}
    volumes:
      - supabase_db_data:/var/lib/postgresql/data
    ports:
      - "54322:5432"
    command:
      - postgres
      - -c
      - config_file=/etc/postgresql/postgresql.conf
      - -c
      - log_min_messages=WARNING
      - -c
      - log_min_error_statement=WARNING
      - -c
      - log_min_duration_statement=1000
      - -c
      - log_connections=on
      - -c
      - log_disconnections=on
      - -c
      - log_duration=on
      - -c
      - log_hostname=on
      - -c
      - log_line_prefix=%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h
      - -c
      - log_lock_waits=on
      - -c
      - log_statement=none
      - -c
      - log_temp_files=0
      - -c
      - track_activities=on
      - -c
      - track_counts=on
    restart: unless-stopped
    networks:
      - database-net

  supabase-auth:
    image: supabase/gotrue:v2.60.7
    container_name: supabase-auth
    depends_on:
      - supabase-db
    environment:
      GOTRUE_DB_DRIVER: postgres
      GOTRUE_DB_DATABASE_URL: postgres://postgres:postgres@supabase-db:5432/postgres?search_path=auth
      PORT: 9999
      GOTRUE_API_HOST: 0.0.0.0
      GOTRUE_API_PORT: 9999
      GOTRUE_JWT_SECRET: ${JWT_SECRET:-super-secret-jwt-token-with-at-least-32-characters-long}
      GOTRUE_JWT_EXP: 3600
      GOTRUE_JWT_AUD: authenticated
      GOTRUE_SITE_URL: http://localhost:3000
      GOTRUE_URI_ALLOW_LIST: ""
      GOTRUE_DISABLE_SIGNUP: false
      GOTRUE_JWT_ADMIN_ROLES: service_role
      GOTRUE_JWT_DEFAULT_GROUP_NAME: authenticated
      GOTRUE_JWT_GROUPS_NAMESPACE: ""
      GOTRUE_MAILER_AUTOCONFIRM: true
      GOTRUE_SMTP_HOST: ""
      GOTRUE_SMTP_PORT: ""
      GOTRUE_SMTP_USER: ""
      GOTRUE_SMTP_PASS: ""
      GOTRUE_SMTP_ADMIN_EMAIL: ""
      GOTRUE_MAILER_URLPATHS_INVITE: /auth/v1/verify
      GOTRUE_MAILER_URLPATHS_CONFIRMATION: /auth/v1/verify
      GOTRUE_MAILER_URLPATHS_RECOVERY: /auth/v1/verify
      GOTRUE_MAILER_URLPATHS_EMAIL_CHANGE: /auth/v1/verify
      GOTRUE_EXTERNAL_EMAIL_ENABLED: true
      GOTRUE_EXTERNAL_PHONE_ENABLED: false
      GOTRUE_SMS_AUTOCONFIRM: true
    ports:
      - "9999:9999"
    restart: unless-stopped
    networks:
      - database-net

volumes:
  supabase_db_data:

networks:
  database-net:
    driver: bridge
EOF

# Start database services
cd /opt/database/postgres
docker-compose up -d

cd /opt/database/supabase
docker-compose up -d

echo "Database stack setup completed."