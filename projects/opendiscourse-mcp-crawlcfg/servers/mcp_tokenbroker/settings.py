import os, yaml
from pydantic import BaseModel, Field
from typing import Any, Dict

class TBSettings(BaseModel):
    storage_backend: str = Field(default=os.environ.get("SECRETS_BACKEND", "vault"))
    policy: Dict[str, Any] = Field(default_factory=dict)

def load_tb_settings() -> TBSettings:
    path = os.path.join(os.path.dirname(__file__), "config", "default.yml")
    cfg = {}
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            cfg = yaml.safe_load(f) or {}
    return TBSettings(**cfg)

settings = load_tb_settings()
