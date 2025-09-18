
#!/usr/bin/env python3
import os, re, json, hashlib, uuid, time
from typing import List, Dict, Any, Optional
import requests

GITHUB_API = os.environ.get("GITHUB_API_URL", "https://api.github.com")
GH_TOKEN = os.environ.get("GH_PAT") or os.environ.get("GITHUB_TOKEN")

def _headers():
    if not GH_TOKEN:
        raise SystemExit("Missing token: set GH_PAT or GITHUB_TOKEN in env.")
    return {
        "Authorization": f"Bearer {GH_TOKEN}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28"
    }

def repo_env():
    owner = os.environ.get("GITHUB_REPOSITORY_OWNER") or os.environ.get("GH_OWNER")
    repo = os.environ.get("GITHUB_REPOSITORY", "").split("/")[-1] or os.environ.get("GH_REPO")
    if not owner or not repo:
        raise SystemExit("Set GH_OWNER and GH_REPO or run within GitHub Actions.")
    return owner, repo

def stable_uuid(namespace: str, text: str) -> str:
    # Use deterministic v5 uuid over content
    ns = uuid.uuid5(uuid.NAMESPACE_URL, namespace)
    return str(uuid.uuid5(ns, text))

def gh_rest(method: str, path: str, **kwargs):
    url = f"{GITHUB_API}{path}"
    r = requests.request(method, url, headers=_headers(), timeout=30, **kwargs)
    if r.status_code >= 400:
        raise SystemExit(f"GitHub API error {r.status_code}: {r.text}")
    return r.json() if r.text else {}

def find_issue_by_label(owner: str, repo: str, microgoal_label: str) -> Optional[Dict[str, Any]]:
    # Search issues with a unique label
    qs = f"repo:{owner}/{repo} is:issue label:\"{microgoal_label}\""
    data = gh_rest("GET", f"/search/issues?q={requests.utils.quote(qs)}")
    items = data.get("items", [])
    return items[0] if items else None

def create_issue(owner: str, repo: str, title: str, body: str, labels: list, assignees: list = None):
    payload = {"title": title, "body": body, "labels": labels}
    if assignees:
        payload["assignees"] = assignees
    return gh_rest("POST", f"/repos/{owner}/{repo}/issues", json=payload)

def update_issue(owner: str, repo: str, number: int, title: Optional[str]=None, body: Optional[str]=None, labels: Optional[list]=None, state: Optional[str]=None):
    payload = {}
    if title is not None: payload["title"] = title
    if body is not None: payload["body"] = body
    if labels is not None: payload["labels"] = labels
    if state is not None: payload["state"] = state
    return gh_rest("PATCH", f"/repos/{owner}/{repo}/issues/{number}", json=payload)
