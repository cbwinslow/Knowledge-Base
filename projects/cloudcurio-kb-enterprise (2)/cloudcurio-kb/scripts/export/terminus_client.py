import os, httpx, typing as t

class TerminusClient:
    def __init__(self, url: str|None=None, user: str|None=None, password: str|None=None, db: str|None=None):
        self.url = (url or os.getenv("TERMINUSDB_URL","http://terminusdb:6363")).rstrip("/")
        self.auth = (user or os.getenv("TERMINUSDB_USER","admin"), password or os.getenv("TERMINUSDB_PASS","password"))
        self.db = os.getenv("TERMINUSDB_DB","kb") if db is None else db

    async def list_documents(self, start: int=0, count: int=1000, document_type: str|None=None) -> list[dict]:
        params = {"start": start, "count": count}
        if document_type: params["type"] = document_type
        async with httpx.AsyncClient(timeout=None, auth=self.auth) as client:
            r = await client.get(f"{self.url}/api/document/admin/{self.db}", params=params)
            r.raise_for_status()
            return r.json()

    async def commits_since(self, branch: str="kb/main", since: str|None=None) -> list[dict]:
        params = {"branch": branch}
        if since: params["since"] = since
        async with httpx.AsyncClient(timeout=None, auth=self.auth) as client:
            r = await client.get(f"{self.url}/api/log/admin/{self.db}", params=params)
            r.raise_for_status()
            return r.json()
