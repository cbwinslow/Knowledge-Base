#!/usr/bin/env python3
import subprocess, sys, yaml, re, os, pathlib
REG_PATH = pathlib.Path('/etc/cbw/ports.yaml')

def load_registry():
    with open(REG_PATH) as f: return yaml.safe_load(f)

def used_ports():
    try:
        out = subprocess.check_output(["ss","-tulpen"], stderr=subprocess.DEVNULL).decode()
    except Exception:
        out = subprocess.check_output(["lsof","-i","-P","-n"]).decode()
    ports=set()
    for line in out.splitlines():
        m=re.search(r":(\d+)\b", line)
        if m: ports.add(int(m.group(1)))
    return ports

def next_free(preferred, used):
    p=preferred
    while p in used: p+=1
    return p

def patch_compose_files(base_dir, mapping):
    for yml in pathlib.Path(base_dir).glob("docker/compose/*.yml"):
        text=yml.read_text()
        changed=False
        for key,(old,new) in mapping.items():
            if old!=new:
                text2=re.sub(rf'(^\s*-\s*"){old}(:\d+")', rf'\1{new}\2', text, flags=re.M)
                if text2!=text:
                    changed=True; text=text2
        if changed:
            yml.write_text(text); print(f"[patched] {yml}")

def main():
    if not REG_PATH.exists():
        print(f"[!] Registry {REG_PATH} missing."); sys.exit(1)
    reg=load_registry(); used=used_ports(); changes={}
    for name,port in reg.items():
        if port in used:
            newp=next_free(port, used); changes[name]=(port,newp); used.add(newp)
        else:
            changes[name]=(port,port)
    if any(old!=new for _,(old,new) in changes.items()):
        print("[!] Conflicts detected; proposing remaps:")
        for k,(old,new) in changes.items():
            if old!=new: print(f"  - {k}: {old} -> {new}")
        base_dir=os.environ.get("CBW_BASE", str(pathlib.Path(__file__).resolve().parents[2]))
        patch_compose_files(base_dir, changes)
        REG_PATH.parent.mkdir(parents=True, exist_ok=True)
        with open(REG_PATH,"w") as f: yaml.safe_dump({k:v[1] for k,v in changes.items()}, f)
        print("[✓] Updated /etc/cbw/ports.yaml and patched compose files.")
    else:
        print("[✓] No conflicts found.")
if __name__=="__main__": main()
