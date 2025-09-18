
#!/usr/bin/env python3
import os, re, sys, json, time
from typing import List, Dict, Any
from common import repo_env, gh_rest

ROUTING_RULES = [
    (lambda labels, title: any('db' in l for l in labels) or re.search(r'\b(vector|pg|weaviate|postgres)\b', title, re.I), 'agent/ollama'),
    (lambda labels, title: re.search(r'\bscript|ci|build|action|workflow\b', title, re.I), 'agent/codex'),
    (lambda labels, title: re.search(r'\breview|audit|refactor\b', title, re.I), 'agent/agent-zero'),
]

def main():
    owner, repo = repo_env()
    # List open issues
    issues = gh_rest("GET", f"/repos/{owner}/{repo}/issues?state=open&per_page=100")
    for it in issues:
        if "pull_request" in it:
            continue  # skip PRs
        title = it["title"]
        number = it["number"]
        labels = [l["name"] for l in it.get("labels", [])]
        # Skip if already has an agent label
        if any(l.startswith("agent/") for l in labels):
            continue
        assigned = None
        for rule, agent in ROUTING_RULES:
            if rule(labels, title):
                assigned = agent
                break
        if not assigned:
            assigned = "agent/copilot"
        new_labels = labels + [assigned]
        gh_rest("PATCH", f"/repos/{owner}/{repo}/issues/{number}", json={"labels": new_labels})
        print(f"Issue #{number}: labeled {assigned}")

if __name__ == "__main__":
    main()
