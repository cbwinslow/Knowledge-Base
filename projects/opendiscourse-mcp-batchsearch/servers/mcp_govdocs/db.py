import os
import psycopg
from contextlib import contextmanager

def get_db_dsn():
    host = os.environ.get("POSTGRES_HOST", "localhost")
    port = os.environ.get("POSTGRES_PORT", "5432")
    db = os.environ.get("POSTGRES_DB", "opendiscourse")
    user = os.environ.get("POSTGRES_USER", "opendiscourse")
    pw = os.environ.get("POSTGRES_PASSWORD", "opendiscourse")
    return f"postgresql://{user}:{pw}@{host}:{port}/{db}"

@contextmanager
def db_conn():
    dsn = get_db_dsn()
    with psycopg.connect(dsn) as conn:
        yield conn
