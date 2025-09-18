from __future__ import annotations
import os, yaml
from typing import Dict, Any

def deep_merge(a: Dict[str, Any], b: Dict[str, Any]) -> Dict[str, Any]:
    out = dict(a)
    for k, v in b.items():
        if k in out and isinstance(out[k], dict) and isinstance(v, dict):
            out[k] = deep_merge(out[k], v)
        else:
            out[k] = v
    return out

def load_yaml(path: str) -> Dict[str, Any]:
    if not os.path.exists(path):
        return {}
    with open(path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}
    # env expansion of ${VAR:-default} simple form
    def expand(val):
        import re
        if isinstance(val, str):
            pattern = r"\$\{([^}:]+)(:-([^}]*))?\}"
            def repl(m):
                var = m.group(1); default = m.group(3) or ""
                return os.environ.get(var, default)
            return re.sub(pattern, repl, val)
        if isinstance(val, dict):
            return {k: expand(v) for k, v in val.items()}
        if isinstance(val, list):
            return [expand(x) for x in val]
        return val
    return expand(data)

def load_settings_for(domain: str | None = None) -> Dict[str, Any]:
    base_dir = os.path.dirname(__file__)
    default = load_yaml(os.path.join(base_dir, "config", "default.yml"))
    if domain:
        site_path = os.path.join(base_dir, "config", "sites", f"{domain}.yml")
        site = load_yaml(site_path)
        return deep_merge(default, site)
    return default
