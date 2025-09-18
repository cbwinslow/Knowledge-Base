from fastapi import FastAPI
from pydantic import BaseModel
from typing import Any, Dict
import uvicorn

app = FastAPI(title="MCP TokenBroker", version="0.2.0")

class JSONRPCRequest(BaseModel):
    jsonrpc: str
    method: str
    params: Dict[str, Any] | None = None
    id: str | int | None = None

@app.get("/healthz")
async def healthz():
    return {"ok": True, "name": "mcp_tokenbroker"}

class MethodNotFound(Exception): ...

async def dispatch(method: str, params: Dict[str, Any]):
    if method == "record_flow":
        return {"flow_id": "stub-flow"}
    if method == "replay_flow":
        return {"status": "ok", "token_ref": "secret://stub/ref"}
    if method == "store_secret":
        return {"ok": True, "ref": params.get("ref", "secret://stub/ref")}
    raise MethodNotFound(f"Unknown tool: {method}")

@app.post("/mcp")
async def mcp(req: JSONRPCRequest):
    try:
        res = await dispatch(req.method, req.params or {})
        return {"jsonrpc": "2.0", "result": res, "id": req.id}
    except MethodNotFound as e:
        return {"jsonrpc": "2.0", "error": {"code": -32601, "message": str(e)}, "id": req.id}
    except Exception:
        return {"jsonrpc": "2.0", "error": {"code": -32603, "message": "Internal error"}, "id": req.id}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8002)
