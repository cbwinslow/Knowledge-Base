import os, json, yaml
from typing import Any, Dict
from urllib.parse import urlparse

def out_dir_for(base_url: str) -> str:
    host = urlparse(base_url).hostname or "output"
    d = os.path.join("out", host)
    os.makedirs(d, exist_ok=True)
    return d

def auth_hint_to_postman(auth_hint: str | None) -> Dict[str, Any] | None:
    if not auth_hint: return None
    low = auth_hint.lower()
    if "bearer" in low: return {"type": "bearer", "bearer": [{"key":"token","value":"{{BEARER_TOKEN}}"}]}
    if "basic" in low: return {"type": "basic", "basic": [{"key":"username","value":"{{BASIC_USER}}"},{"key":"password","value":"{{BASIC_PASS}}"}]}
    return {"type": "apikey", "apikey": [{"key":"key","value":"{{API_KEY}}"},{"key":"in","value":"header"}]}

async def write_openapi_and_postman(base_url: str, summary: Dict[str, Any], outdir: str) -> None:
    paths = {}
    for p in summary.get("probes", []):
        path = urlparse(p.get("url")) .path
        schema = {"type":"object"}
        paths[path] = {"get":{"responses":{"200":{"description":"ok","content":{"application/json":{"schema":schema}}}}}}
    openapi = {"openapi":"3.0.3","info":{"title":"Recon","version":"0.3"},"servers":[{"url":base_url}],"paths":paths}
    with open(os.path.join(outdir,"openapi.yaml"),"w") as f: yaml.safe_dump(openapi,f)
    postman = {"info":{"name":"API Recon"},"item":[]}
    with open(os.path.join(outdir,"postman_collection.json"),"w") as f: json.dump(postman,f)
