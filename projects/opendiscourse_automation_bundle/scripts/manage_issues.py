
#!/usr/bin/env python3
import os, sys, json, re
from typing import Dict, List
from slugify import slugify
from common import repo_env, stable_uuid, find_issue_by_label, create_issue, update_issue

def load_json_from_cmd(cmd: str) -> List[Dict]:
    # helper if needed later
    return []

def read_json(path: str) -> List[Dict]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def task_to_issue_payload(task: Dict) -> Dict:
    # Build labels: area/* from tags, priority, microgoal
    text = (task.get("title","") + "|" + task.get("description","")).strip()
    micro_id = task.get("id") or stable_uuid("https://opendiscourse.net/microgoal", text)
    labels = []
    for tag in task.get("tags", []):
        labels.append(f"area/{slugify(tag)}")
    labels.append(f"priority/{task.get('priority','P3')}")
    labels.append(f"microgoal:{micro_id}")
    title = task.get("title","").strip()[:255]
    body = task.get("description","").strip()
    if body:
        body += "\n\n"
    body += f"---\n**Microgoal ID:** `{micro_id}`\n\n- [ ] Acceptance criteria defined\n- [ ] Tests added\n- [ ] Docs updated\n"
    return {"title": title, "body": body, "labels": labels, "micro_label": f"microgoal:{micro_id}"}

def main():
    owner, repo = repo_env()

    tasks = []
    if os.path.exists("tasks.json"):
        tasks += read_json("tasks.json")
    if os.path.exists("microgoals.json"):
        tasks += read_json("microgoals.json")

    for t in tasks:
        payload = task_to_issue_payload(t)
        existing = find_issue_by_label(owner, repo, payload["micro_label"])
        if existing:
            number = existing["number"]
            update_issue(owner, repo, number, title=payload["title"], body=payload["body"], labels=payload["labels"])
            print(f"Updated issue #{number}: {payload['title']}")
        else:
            res = create_issue(owner, repo, payload["title"], payload["body"], payload["labels"])
            print(f"Created issue #{res.get('number')}: {payload['title']}")

if __name__ == "__main__":
    main()
