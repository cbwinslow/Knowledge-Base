from pydantic import BaseModel, Field
import os

class Settings(BaseModel):
    postgres_host: str = Field(default=os.environ.get("POSTGRES_HOST", "localhost"))
    postgres_port: int = Field(default=int(os.environ.get("POSTGRES_PORT", "5432")))
    postgres_db: str = Field(default=os.environ.get("POSTGRES_DB", "opendiscourse"))
    postgres_user: str = Field(default=os.environ.get("POSTGRES_USER", "opendiscourse"))
    postgres_password: str = Field(default=os.environ.get("POSTGRES_PASSWORD", "opendiscourse"))

settings = Settings()
