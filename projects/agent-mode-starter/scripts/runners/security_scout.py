#!/usr/bin/env python3
from __future__ import annotations
from typing import Dict, Any, List
from .base import BaseRunner
try:
    import paramiko  # type: ignore
    import requests  # type: ignore
except Exception:
    paramiko = None  # type: ignore
    requests = None  # type: ignore
APT_UPGR = "bash -lc 'apt -qq list --upgradable 2>/dev/null | cut -d/ -f1 | sed \"s/\\[upgradable.*//\"'"
class Runner(BaseRunner):
    def _list_upgrades(self, addr: str, username: str, key_path: str) -> List[str]:
        if not paramiko:
            return ["openssl","curl","libxml2"]
        pkgs: List[str] = []
        try:
            c = paramiko.SSHClient(); c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            c.connect(addr, username=username, key_filename=key_path, look_for_keys=True, timeout=8)
            _, out, _ = c.exec_command(APT_UPGR, timeout=15)
            for line in out.read().decode().splitlines():
                t = line.strip()
                if t: pkgs.append(t)
            c.close()
        except Exception as e:
            self.logger.warning(f"SSH upgrade check failed for {addr}: {e}")
        return pkgs
    def _osv_lookup(self, pkg: str) -> str:
        if not requests: return "(no OSV)"
        try:
            r = requests.post("https://api.osv.dev/v1/query", json={"package": {"name": pkg, "ecosystem": "Debian"}}, timeout=10)
            vulns = r.json().get("vulns", [])
            if not vulns: return "no known CVEs"
            ids = ", ".join(v.get("id","?") for v in vulns[:5])
            more = max(0, len(vulns)-5)
            return f"CVEs: {ids}" + (f" (+{more} more)" if more else "")
        except Exception as e:
            self.logger.warning(f"OSV lookup failed for {pkg}: {e}")
            return "(OSV error)"
    def run(self) -> int:
        hosts: List[Dict[str, Any]] = self.globals.get('hosts', []) or []
        username: str = self.globals.get('ssh', {}).get('username', 'cbwinslow')
        key_path: str = self.globals.get('ssh', {}).get('key_path', '~/.ssh/id_ed25519')
        lines: List[str] = ["# CVE Alerts\n"]
        for h in hosts:
            pkgs = self._list_upgrades(h['address'], username, key_path)
            if not pkgs:
                lines.append(f"- {h['name']}: no upgrades found\n"); continue
            lines.append(f"- {h['name']}: {len(pkgs)} upgradable packages\n")
            for p in pkgs[:10]:
                lines.append(f"  - {p}: {self._osv_lookup(p)}\n")
        md = "".join(lines)
        out = next((o for o in self.agent['outputs'] if o['type']=='markdown'), None)
        if out: self.emit_markdown(out['path'], md)
        return 0
