
#!/usr/bin/env python3
import re, sys, json
from typing import List, Dict

def extract_microgoals(md: str) -> List[Dict]:
    # Look for a section titled "Next Steps" or "Microgoals" and parse list items
    micro = []
    sec = re.split(r"(?mi)^##\s*(Microgoals|Next\s*Steps)\s*$", md)
    if len(sec) >= 3:
        target = sec[2]
        for m in re.finditer(r"^\s*(?:\d+\.|-)\s+(.*)$", target, flags=re.MULTILINE):
            title = m.group(1).strip()
            micro.append({
                "title": title,
                "tags": ["microgoal"],
                "priority": "P2"
            })
    return micro

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "SRS.md"
    with open(path, "r", encoding="utf-8") as f:
        md = f.read()
    items = extract_microgoals(md)
    print(json.dumps(items, indent=2))

if __name__ == "__main__":
    main()
