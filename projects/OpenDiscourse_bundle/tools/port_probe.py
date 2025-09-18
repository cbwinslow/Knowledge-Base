#!/usr/bin/env python3

"""Probe listening ports and fingerprint versions (Postgres, Redis, MinIO, Neo4j)."""

import json, re, shutil, subprocess, http.client

REQ = {
  "postgres": {"bin": "psql", "min_major": 16, "default_port": 5432, "probe": [5432,5433,5434]},
  "redis":    {"bin": "redis-cli", "min_major": 7,  "default_port": 6379, "probe": [6379,6380]},
  "minio":    {"bin": "minio", "min_major": 2023, "default_port": 9000, "probe": [9000,9001]},
  "neo4j":    {"bin": "neo4j", "min_major": 5,  "default_port": 7687, "probe": [7687,7474]},
}
DEF_TIMEOUT = 0.25

def which(x): 
    return shutil.which(x) is not None

def tcp_listening_ports():
    try:
        out = subprocess.check_output(["ss","-lntp"], text=True)
    except Exception:
        out = subprocess.check_output(["netstat","-lntp"], text=True)
    ports = set()
    for ln in out.splitlines():
        m = re.search(r":(\d+)\s+", ln)
        if m:
            ports.add(int(m.group(1)))
    return ports

def try_http_head(port, path="/", host="127.0.0.1"):
    try:
        conn = http.client.HTTPConnection(host, port, timeout=DEF_TIMEOUT)
        conn.request("HEAD", path)
        return conn.getresponse().status
    except Exception:
        return None

VERSION_CACHE = {}
DEF_MAJOR = re.compile(r"(\d+)\.(\d+)")
MINIO_YEAR = re.compile(r"RELEASE\.(\d{4})-")

def version_text(cmd):
    if cmd in VERSION_CACHE: 
        return VERSION_CACHE[cmd]
    try:
        out = subprocess.check_output([cmd, "--version"], text=True, stderr=subprocess.STDOUT)
        VERSION_CACHE[cmd] = out.strip(); 
        return VERSION_CACHE[cmd]
    except Exception:
        VERSION_CACHE[cmd] = None
        return None

def parse_major(s, name):
    if not s: 
        return None
    if name == "minio":
        m = MINIO_YEAR.search(s)
        if m: 
            return int(m.group(1))
    m = DEF_MAJOR.search(s); 
    return int(m.group(1)) if m else None

def main():
    listening = tcp_listening_ports(); found = {}
    for name, spec in REQ.items():
        present = which(spec["bin"]) if spec["bin"] else False
        ver_text = version_text(spec["bin"]) if present else None
        major = parse_major(ver_text, name)
        ports = [p for p in spec["probe"] if p in listening]
        if name == "minio" and not ports and (try_http_head(9000) in (200,204,301,302)): ports.append(9000)
        if name == "neo4j" and not ports and (try_http_head(7474) in (200,401)): ports.append(7474)
        compat = (major is not None and major >= spec["min_major"]) if (present or ports) else False
        found[name] = {"bin_present": present, "version_text": ver_text, "major": major, "ports": ports,
                       "default_port": spec["default_port"], "min_major": spec["min_major"], "compatible": bool(compat)}
    print(json.dumps(found, indent=2))

if __name__ == "__main__": 
    main()
