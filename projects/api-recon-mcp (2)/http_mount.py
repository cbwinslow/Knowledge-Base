from starlette.applications import Starlette
from starlette.routing import Mount
from mcp_server import build_mcp
mcp = build_mcp()
app = Starlette(routes=[Mount("/mcp", app=mcp.streamable_http_app())])
