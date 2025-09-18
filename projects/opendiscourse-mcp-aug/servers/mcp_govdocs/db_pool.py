from psycopg_pool import ConnectionPool
from settings import settings

pool = ConnectionPool(f"postgresql://{settings.postgres_user}:{settings.postgres_password}@{settings.postgres_host}:{settings.postgres_port}/{settings.postgres_db}", max_size=10)
