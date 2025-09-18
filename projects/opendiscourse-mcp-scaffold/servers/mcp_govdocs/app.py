from fastapi import FastAPI, Request
from pydantic import BaseModel
from typing import Any, Dict
from mcp_tools import MCPRouter
import uvicorn

app = FastAPI(title="MCP GovDocs", version="0.1.0")
router = MCPRouter()

class JSONRPCRequest(BaseModel):
    jsonrpc: str
    method: str
    params: Dict[str, Any] | None = None
    id: str | int | None = None

@app.get("/healthz")
async def healthz():
    return {"ok": True, "name": "mcp_govdocs"}

@app.post("/mcp")
async def mcp_endpoint(body: JSONRPCRequest):
    result = await router.dispatch(body.method, body.params or {})
    return {"jsonrpc": "2.0", "result": result, "id": body.id}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
