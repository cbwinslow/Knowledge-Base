#!/usr/bin/env python3
import os, json, httpx, anyio

TERMINUSDB_URL = os.getenv("TERMINUSDB_URL","http://terminusdb:6363")
DB = os.getenv("TERMINUSDB_DB","kb")
AUTH=(os.getenv("TERMINUSDB_USER","admin"), os.getenv("TERMINUSDB_PASS","password"))

async def main():
    async with httpx.AsyncClient(timeout=15, auth=AUTH) as client:
        r = await client.get(f"{TERMINUSDB_URL}/api/db/admin/{DB}")
        if r.status_code == 404:
            cr = await client.post(f"{TERMINUSDB_URL}/api/db/admin/{DB}", json={"label": DB, "comment": "CloudCurio KB"})
            cr.raise_for_status()
        for br in ("kb/main","kb/drafts"):
            rb = await client.get(f"{TERMINUSDB_URL}/api/db/admin/{DB}/branch")
            names=[b.get('name') for b in (rb.json() or [])]
            if br not in names:
                cb = await client.post(f"{TERMINUSDB_URL}/api/db/admin/{DB}/branch/{br}")
                cb.raise_for_status()
        schema_dir=os.path.join(os.path.dirname(__file__),"..","schemas","terminusdb")
        files=["context.json","document.json","entitykind.json","entity.json","mention.json","relationtype.json","relation.json"]
        classes=[json.loads(open(os.path.join(schema_dir,f)).read()) for f in files]
        ap=await client.put(f"{TERMINUSDB_URL}/api/db/admin/{DB}/schema", json={"schema":classes})
        ap.raise_for_status()
        print("OK: schema applied")

if __name__ == "__main__":
    anyio.run(main)
