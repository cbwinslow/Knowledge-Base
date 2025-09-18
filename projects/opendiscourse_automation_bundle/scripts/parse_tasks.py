
#!/usr/bin/env python3
import re, sys, json, uuid, hashlib
from typing import List, Dict

def parse_markdown_tasks(md: str) -> List[Dict]:
    tasks = []

    # 1) Checklists: - [ ] or - [x]
    for m in re.finditer(r"^- \[( |x)\]\s+(.*)$", md, flags=re.MULTILINE | re.IGNORECASE):
        done = (m.group(1).lower() == "x")
        title = m.group(2).strip()
        tasks.append({
            "id": None,
            "title": title,
            "description": "",
            "done": done,
            "tags": [],
            "priority": "P3"
        })

    # 2) GFM tables with Title column
    table_pattern = re.compile(r"(\|.+\|\s*\n\|[:\-| ]+\|\s*\n(?:\|.*\|\s*\n)+)", re.MULTILINE)
    for block in table_pattern.findall(md):
        lines = [ln.strip() for ln in block.strip().splitlines() if ln.strip()]
        if len(lines) < 3: 
            continue
        headers = [h.strip().strip("|").strip() for h in lines[0].split("|") if h.strip()]
        if not any(h.lower() in ("title","task") for h in headers):
            continue
        idx = {h.lower(): i for i,h in enumerate(headers)}
        for row in lines[2:]:
            cols = [c.strip() for c in row.strip("|").split("|")]
            if len(cols) < len(headers): 
                continue
            title = cols[idx.get("title", idx.get("task", 0))]
            desc = cols[idx.get("description")] if "description" in idx else ""
            prio = cols[idx.get("priority")] if "priority" in idx else "P3"
            tags = [t.strip() for t in (cols[idx.get("tags")] if "tags" in idx else "").split(",") if t.strip()]
            tasks.append({
                "id": None,
                "title": title,
                "description": desc,
                "done": False,
                "tags": tags,
                "priority": prio or "P3"
            })

    # Deduplicate by title
    seen = set()
    unique = []
    for t in tasks:
        if t["title"] in seen:
            continue
        seen.add(t["title"])
        unique.append(t)
    return unique

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "project_tasks.md"
    with open(path, "r", encoding="utf-8") as f:
        md = f.read()
    tasks = parse_markdown_tasks(md)
    print(json.dumps(tasks, indent=2))

if __name__ == "__main__":
    main()
