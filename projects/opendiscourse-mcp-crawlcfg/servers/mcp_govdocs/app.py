from fastapi import FastAPI
from pydantic import BaseModel
from typing import Any, Dict
import uvicorn, logging
from mcp_tools import MCPRouter
from minio_utils import ensure_bucket
from db_pool import pool
from logging_config import configure_logging

configure_logging()
log = logging.getLogger("mcp_govdocs")

app = FastAPI(title="MCP GovDocs", version="0.2.0")
router = MCPRouter()

class JSONRPCRequest(BaseModel):
    jsonrpc: str
    method: str
    params: Dict[str, Any] | None = None
    id: str | int | None = None

@app.on_event("startup")
async def startup():
    # Health check DB
        ensure_bucket()
    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1")

@app.get("/healthz")
async def healthz():
    try:
        with pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
        return {"ok": True, "name": "mcp_govdocs"}
    except Exception as e:
        log.exception("DB health check failed")
        return {"ok": False, "error": str(e)}

@app.post("/mcp")
async def mcp_endpoint(body: JSONRPCRequest):
    try:
        result = await router.dispatch(body.method, body.params or {})
        return {"jsonrpc": "2.0", "result": result, "id": body.id}
    except router.MethodNotFound as e:
        return {"jsonrpc": "2.0", "error": {"code": -32601, "message": str(e)}, "id": body.id}
    except router.InvalidParams as e:
        return {"jsonrpc": "2.0", "error": {"code": -32602, "message": str(e)}, "id": body.id}
    except Exception as e:
        log.exception("Internal error")
        return {"jsonrpc": "2.0", "error": {"code": -32603, "message": "Internal error"}, "id": body.id}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
