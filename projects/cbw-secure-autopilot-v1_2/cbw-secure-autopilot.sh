#!/usr/bin/env bash
# ================================================================================================
# Script: cbw-secure-autopilot.sh
# Author: ChatGPT for Blaine "CBW" Winslow (cbwinslow)
# Date: 2025-09-18
# Summary: End-to-end secure autopilot: IDS, scanners, AI self-heal + YAML playbooks, LocalAI,
#          Prom exporter, report signing, anomaly detection, host hardening, daily reports.
# ================================================================================================
set -euo pipefail
SCRIPT_NAME="cbw-secure-autopilot"; LOG_FILE="/tmp/CBW-${SCRIPT_NAME}.log"
CBW_USER_DEFAULT="${SUDO_USER:-${USER}}"; REPORT_ROOT="/home/${CBW_USER_DEFAULT}/dev/dotfiles/reports/security"
ETC_DIR="/etc/cbw"; BIN_DIR="/usr/local/bin"; OPT_DIR="/opt/cbw"; VAR_DIR="/var/lib/cbw"
SELFHEAL_PY="${OPT_DIR}/ai_selfheal.py"; CFG_FILE="${ETC_DIR}/ai-selfheal.conf"
SYSTEMD_UNIT_AGENT="cbw-ai-selfheal.service"; SYSTEMD_TIMER_AGENT="cbw-ai-selfheal.timer"
SYSTEMD_UNIT_REPORT="cbw-security-report.service"; SYSTEMD_TIMER_REPORT="cbw-security-report.timer"
SYSTEMD_UNIT_EXPORTER="cbw-prom-eve-exporter.service"
LOCALAI_ENABLED=false; LOCALAI_DATA_DIR="/var/lib/localai"; LOCALAI_CONTAINER_NAME="localai"
LOCALAI_IMAGE="localai/localai:latest-cublas"; LOCALAI_PORT="8080"
LOCALAI_MODEL="Qwen2.5-0.5B-Instruct-GGUF"
LOCALAI_MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf?download=true"
INSTALL_ALL=false; ONLY_IDS=false; ONLY_SCANNERS=false; ONLY_AGENT=false; RUN_ONCE=false
LLM_BACKEND="none"; DRY_RUN=false; VERBOSE=false; INSTALL_LOCALAI=false; INSTALL_EXPORTERS=false
INSTALL_HARDENING=false; ENABLE_SIGN=false; ENABLE_ANOMALY=false
log(){ echo "[$(date -Is)] $*" | tee -a "$LOG_FILE" >&2; } ; run(){ $DRY_RUN && { log "[DRY-RUN] $*"; } || { log "RUN: $*"; eval "$@"; }; }
usage(){ cat <<'U'
Usage: sudo ./cbw-secure-autopilot.sh [options]
  --install-all | --only-ids | --only-scanners | --only-agent
  --install-localai --install-exporters --install-hardening
  --enable-report-signing --enable-anomaly
  --llm-backend none|localai|ollama|openrouter|openai
  --run-once --dry-run --verbose --help
U
}
while [[ $# -gt 0 ]]; do case "$1" in
  --install-all) INSTALL_ALL=true;; --only-ids) ONLY_IDS=true;; --only-scanners) ONLY_SCANNERS=true;;
  --only-agent) ONLY_AGENT=true;; --install-localai) INSTALL_LOCALAI=true; LOCALAI_ENABLED=true;;
  --install-exporters) INSTALL_EXPORTERS=true;; --install-hardening) INSTALL_HARDENING=true;;
  --enable-report-signing) ENABLE_SIGN=true;; --enable-anomaly) ENABLE_ANOMALY=true;;
  --llm-backend) LLM_BACKEND="${2:-none}"; shift;; --run-once) RUN_ONCE=true;;
  --dry-run) DRY_RUN=true;; --verbose) VERBOSE=true;; --help|-h) usage; exit 0;;
  *) log "Unknown arg: $1"; usage; exit 1;; esac; shift; done
$INSTALL_LOCALAI || [[ "$LLM_BACKEND" != "localai" ]] || LOCALAI_ENABLED=true
[[ $EUID -eq 0 ]] || { log "Run as root"; exit 1; }
OS_FAMILY=""; command -v apt >/dev/null 2>&1 && OS_FAMILY=debian; command -v dnf >/dev/null 2>&1 && OS_FAMILY=${OS_FAMILY:-rhel}
[[ -n "$OS_FAMILY" ]] || { log "Unsupported OS"; exit 1; }
run "mkdir -p '$REPORT_ROOT' '$ETC_DIR' '$OPT_DIR' '$BIN_DIR' '$VAR_DIR'"
pkg_update(){ [[ $OS_FAMILY == debian ]] && run "apt update" || run "dnf makecache"; }
pkg_install(){ if [[ $OS_FAMILY == debian ]]; then run "DEBIAN_FRONTEND=noninteractive apt install -y $*"; else run "dnf install -y $*"; fi }
# Components
install_localai(){ pkg_update; command -v docker >/dev/null 2>&1 || {
  if [[ $OS_FAMILY == debian ]]; then pkg_install ca-certificates curl gnupg; run "install -m 0755 -d /etc/apt/keyrings";
    run "curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo ${ID})/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg";
    run "chmod a+r /etc/apt/keyrings/docker.gpg";
    run "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo ${ID}) $(. /etc/os-release; echo ${VERSION_CODENAME}) stable\" > /etc/apt/sources.list.d/docker.list";
    pkg_update; pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin;
  else pkg_install dnf-plugins-core; run "dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || true";
    pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; run "systemctl enable --now docker"; fi }
  run "mkdir -p '${LOCALAI_DATA_DIR}/models'"; run "docker pull ${LOCALAI_IMAGE}";
  local MODEL_FILE="${LOCALAI_DATA_DIR}/models/qwen2.5-0.5b-instruct-q4_0.gguf";
  [[ -f "$MODEL_FILE" ]] || run "curl -L --fail --output '${MODEL_FILE}' '${LOCALAI_MODEL_URL}' || true";
  docker ps --format '{{.Names}}' | grep -q "^${LOCALAI_CONTAINER_NAME}$" && run "docker restart ${LOCALAI_CONTAINER_NAME}" || run "docker run -d --restart=unless-stopped -p ${LOCALAI_PORT}:8080 -v ${LOCALAI_DATA_DIR}/models:/models -e MODELS_PATH=/models --name ${LOCALAI_CONTAINER_NAME} ${LOCALAI_IMAGE}";
  run "sleep 3; curl -sSf http://127.0.0.1:${LOCALAI_PORT}/v1/models || true"; }
install_suricata(){ pkg_update; [[ $OS_FAMILY == debian ]] && pkg_install suricata suricata-update jq || { pkg_install suricata jq python3-pip || true; command -v suricata-update >/dev/null || run "pip3 install --quiet suricata-update || true"; };
  command -v suricata-update >/dev/null && run "suricata-update || true"; local yml=/etc/suricata/suricata.yaml; [[ -f $yml ]] && run "cp -a $yml ${yml}.bak.$(date +%s)"; local iface=$(ip route get 1.1.1.1 2>/dev/null|awk '{for(i=1;i<=NF;i++) if ($i=="dev"){print $(i+1); exit}}'); iface=${iface:-eth0}; run "sed -i 's/interface: .*/interface: '\"$iface\"'/' $yml || true"; run "systemctl enable --now suricata"; }
install_snort(){ pkg_update; local ok=false; if [[ $OS_FAMILY == debian ]]; then
    if apt-cache show snort3 >/dev/null 2>&1; then pkg_install snort3; ok=true; run "systemctl enable --now snort3 || true";
    elif apt-cache show snort >/dev/null 2>&1; then pkg_install snort; ok=true; run "systemctl enable --now snort || true"; fi
  else if dnf info snort3 >/dev/null 2>&1; then pkg_install snort3; ok=true; run "systemctl enable --now snort3 || true"; elif dnf info snort >/dev/null 2>&1; then pkg_install snort; ok=true; run "systemctl enable --now snort || true"; fi; fi
  $ok || log "Snort not in repos; skipping"; }
install_scanners(){ pkg_update; [[ $OS_FAMILY == debian ]] && pkg_install rkhunter chkrootkit || pkg_install rkhunter || true; command -v rkhunter >/dev/null && run "rkhunter --propupd || true"; command -v rkhunter >/dev/null && run "rkhunter --update || true"; }
write_config(){ cat > /tmp/ai-selfheal.conf.$$ <<CFG
backend=${LLM_BACKEND}
localai_url=http://127.0.0.1:${LOCALAI_PORT}/v1
localai_model=${LOCALAI_MODEL}
ollama_model=llama3.1
openrouter_api_key=
openrouter_model=google/gemini-2.0-flash-lite-preview-02-05:free
openai_api_key=
openai_model=gpt-4o-mini
max_log_size_mb=256
auto_block_bad_ips=false
block_expire_minutes=60
suricata_eve=/var/log/suricata/eve.json
enable_anomaly=${ENABLE_ANOMALY}
report_signing=${ENABLE_SIGN}
signer_key_path=/root/.minisign/cbw.key
CFG
  run "install -m 0640 /tmp/ai-selfheal.conf.$$ '${CFG_FILE}' && rm -f /tmp/ai-selfheal.conf.$$"; }
install_playbooks(){ run "install -m 0755 -d ${ETC_DIR}/selfheal.d"; cat > /tmp/selfheal-default.yml.$$ <<'Y'
version: 1
rules:
  - name: ensure-suricata-active
    when: ids.suricata.active == False
    action: systemctl restart suricata
    severity: 2
  - name: rotate-giant-syslog-when-df-full
    when: '"100%" in disk.df'
    action: logrotate /etc/logrotate.conf
    severity: 1
  - name: warn-many-high-severity-alerts
    when: len(eve.high_sev_alerts) > 5
    action: noop
    severity: 2
Y
  run "install -m 0644 /tmp/selfheal-default.yml.$$ ${ETC_DIR}/selfheal.d/default.yml && rm -f /tmp/selfheal-default.yml.$$"; }
install_agent(){ write_config; install_playbooks;
  cat > /tmp/ai_selfheal.py.$$ <<'PY'
#!/usr/bin/env python3
# ai_selfheal.py v1.2
import os,sys,json,time,subprocess,shlex,datetime,re
LOG="/tmp/CBW-ai-selfheal.log"; SUMMARY="/tmp/CBW-ai-selfheal-summary.json"
CFG="/etc/cbw/ai-selfheal.conf"; STATE="/var/lib/cbw"; PB_DIR="/etc/cbw/selfheal.d"
from pathlib import Path
def log(m): open(LOG,'a').write(f"[{datetime.datetime.now().isoformat()}] {m}\n")
def run(cmd, timeout=90):
    log(f"RUN: {cmd}")
    try:
        r=subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout.strip(), r.stderr.strip()
    except Exception as e:
        log(f"ERR: {e}"); return 1,"",str(e)
def load_cfg():
    d={"backend":"none","localai_url":"http://127.0.0.1:8080/v1","localai_model":"Qwen2.5-0.5B-Instruct-GGUF",
       "max_log_size_mb":"256","auto_block_bad_ips":"false","block_expire_minutes":"60",
       "suricata_eve":"/var/log/suricata/eve.json","enable_anomaly":"false","report_signing":"false"}
    try:
        for line in open(CFG):
            line=line.strip()
            if not line or line.startswith('#') or '=' not in line: continue
            k,v=line.split('=',1); d[k.strip()]=v.strip()
    except Exception as e: log(f"CFG load err: {e}")
    return d
def service_active(u): return run(f"systemctl is-active {shlex.quote(u)}")[1].strip()=="active"
def try_restart(u): run(f"systemctl restart {shlex.quote(u)}"); time.sleep(1); return service_active(u)
def disk_df(): return run("df -h")[1]
def eve_parse(path, limit=1000):
    items=[]; high=[]
    if not os.path.isfile(path): return items, high
    rc,out,_=run(f"tail -n {limit} {shlex.quote(path)}")
    for ln in out.splitlines():
        try:
            j=json.loads(ln)
            if j.get('event_type')=='alert':
                sev=j.get('alert',{}).get('severity',0)
                it={"sev":sev,"src":j.get('src_ip'),"dst":j.get('dest_ip'),"sig":j.get('alert',{}).get('signature')}
                items.append(it)
                if int(sev)>=2: high.append(it)
        except Exception: pass
    return items, high
def load_playbooks():
    try:
        import yaml
    except Exception:
        return []
    res=[]
    for p in sorted(Path(PB_DIR).glob('*.yml')):
        try: res.append((p.name, __import__('yaml').safe_load(open(p))))
        except Exception as e: log(f"PB load {p}: {e}")
    return res
def eval_rule(expr, ctx):
    try: return bool(eval(expr, {'__builtins__':{}}, {'len':len, **ctx}))
    except Exception as e: log(f"rule eval err: {e}"); return False
def enforce_logs(max_mb):
    acts=[]; 
    for p in ["/var/log/suricata/eve.json","/var/log/syslog","/var/log/messages"]:
        if os.path.isfile(p) and (os.path.getsize(p)/1024/1024)>max_mb:
            ts=datetime.datetime.now().strftime('%Y%m%d%H%M%S'); run(f"mv {shlex.quote(p)} {shlex.quote(p)}.{ts}"); run(f"truncate -s0 {shlex.quote(p)} || true"); acts.append(f"rotated:{p}")
    return acts
def anomaly_counts(alerts): return {"high": len([a for a in alerts if int(a.get('sev',0))>=2])}
def llm_advice(cfg, context):
    if cfg.get('backend','none')=='localai':
        url=cfg.get('localai_url','http://127.0.0.1:8080/v1'); model=cfg.get('localai_model')
        try:
            import urllib.request, json as js
            payload={"model":model, "messages":[{"role":"user","content": context+"\nReturn 3–5 concise, safe remediations."}]}
            req=urllib.request.Request(url+"/chat/completions", data=js.dumps(payload).encode(), headers={"Content-Type":"application/json"})
            with urllib.request.urlopen(req, timeout=25) as r: data=js.loads(r.read().decode())
            return data.get('choices',[{}])[0].get('message',{}).get('content','')[:4000]
        except Exception as e: log(f"LLM err: {e}")
    return ""
def main():
    os.makedirs(STATE, exist_ok=True)
    cfg=load_cfg(); eve_all,eve_hi=eve_parse(cfg.get('suricata_eve','/var/log/suricata/eve.json'))
    ids={s:{'active':service_active(s)} for s in ['suricata','snort','snort3']}
    acts=[]; acts+=enforce_logs(int(cfg.get('max_log_size_mb','256')))
    if not ids['suricata']['active'] and try_restart('suricata'): acts.append('restarted:suricata')
    ctx={'ids':ids,'disk': {'df': disk_df()},'eve': {'recent': eve_all[:100], 'high_sev_alerts': eve_hi[:50]}}
    for name,pb in load_playbooks(): 
        for rule in (pb.get('rules') or []):
            if eval_rule(str(rule.get('when','False')), ctx):
                act = rule.get('action','noop')
                if act not in ('noop',''): run(act)
                acts.append(f"rule:{rule.get('name')} -> {act}")
    anomaly = anomaly_counts(eve_hi) if cfg.get('enable_anomaly','false').lower()=='true' else {}
    advice = llm_advice(cfg, json.dumps({'ids':ids,'eve_high':eve_hi[:20],'anomaly':anomaly}, indent=2)[:6000])
    summary={'ts': datetime.datetime.now().isoformat(),'ids_status': ids,'eve_alerts_recent': eve_all[:150],'actions': acts,'anomaly': anomaly,'llm_advice': advice}
    open(SUMMARY,'w').write(json.dumps(summary, indent=2)); print(SUMMARY)
if __name__=='__main__': main()
PY
  run "install -m 0755 /tmp/ai_selfheal.py.$$ '${SELFHEAL_PY}' && rm -f /tmp/ai_selfheal.py.$$"
  cat > /tmp/${SYSTEMD_UNIT_AGENT}.$$ <<UNIT
[Unit]
Description=CBW AI Self-Heal Agent (hourly)
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
ExecStart=${SELFHEAL_PY}
User=root
Group=root
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
PrivateDevices=true
NoNewPrivileges=true
CapabilityBoundingSet=
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictRealtime=true
RestrictSUIDSGID=true
ProtectKernelLogs=true
ProtectKernelTunables=true
ReadWritePaths=/var/lib/cbw /tmp
[Install]
WantedBy=multi-user.target
UNIT
  run "install -m 0644 /tmp/${SYSTEMD_UNIT_AGENT}.$$ /etc/systemd/system/${SYSTEMD_UNIT_AGENT} && rm -f /tmp/${SYSTEMD_UNIT_AGENT}.$$"
  cat > /tmp/${SYSTEMD_TIMER_AGENT}.$$ <<T
[Unit]
Description=Run CBW AI Self-Heal hourly
[Timer]
OnBootSec=5m
OnUnitActiveSec=60m
Unit=${SYSTEMD_UNIT_AGENT}
[Install]
WantedBy=timers.target
T
  run "install -m 0644 /tmp/${SYSTEMD_TIMER_AGENT}.$$ /etc/systemd/system/${SYSTEMD_TIMER_AGENT} && rm -f /tmp/${SYSTEMD_TIMER_AGENT}.$$"
  run "systemctl daemon-reload"; run "systemctl enable --now ${SYSTEMD_TIMER_AGENT}"; }
install_reporting(){
  cat > /tmp/cbw-generate-security-report.$$ <<'SH'
#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-cbw-generate-security-report.log"; echo "[$(date -Is)] generating report" >> "$LOG"
CBW_USER="${SUDO_USER:-${USER}}"; ROOT="/home/${CBW_USER}/dev/dotfiles/reports/security"; DATE_DIR="$(date +%F)"; OUT_DIR="${ROOT}/${DATE_DIR}"; mkdir -p "${OUT_DIR}"
SUMMARY="$((/opt/cbw/ai_selfheal.py) 2>/dev/null || true)"; [[ -f "${SUMMARY}" ]] || SUMMARY="/tmp/CBW-ai-selfheal-summary.json"
RKH="${OUT_DIR}/rkhunter.txt"; CHK="${OUT_DIR}/chkrootkit.txt"
( command -v rkhunter >/dev/null && rkhunter --check --sk --rwo >"${RKH}" 2>&1 ) || echo "rkhunter not present" >"${RKH}"
( command -v chkrootkit >/dev/null && chkrootkit >"${CHK}" 2>&1 ) || echo "chkrootkit not present" >"${CHK}"
FS_TXT="${OUT_DIR}/filesystem_audit.txt"
{ echo "== df -h =="; df -h; echo; echo "== lsblk =="; lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT;
  echo; echo "== Largest files (top 80) =="; bash -lc "find / -xdev -type f -printf '%T@ %s %p\n' 2>/dev/null | sort -nr | head -n 80";
  echo; echo "== SUID (top 200) =="; bash -lc "find / -xdev -perm -4000 -type f 2>/dev/null | head -n 200";
  echo; echo "== World-writable dirs (top 200) =="; bash -lc "find / -xdev -type d -perm -0002 2>/dev/null | head -n 200";
  echo; echo "== Broken symlinks (top 200) =="; bash -lc "find / -xdev -xtype l 2>/dev/null | head -n 200"; } > "${FS_TXT}"
MD="${OUT_DIR}/SECURITY_REPORT_${DATE_DIR}.md"
echo "# Daily Security Report - ${DATE_DIR}" > "${MD}"; echo >> "${MD}"
echo "- Reports dir: \`${OUT_DIR}\`" >> "${MD}"; echo "- JSON summary: \`${SUMMARY}\`" >> "${MD}"; echo >> "${MD}"
echo "## Triage Checklist" >> "${MD}"; echo "- [ ] IDS active" >> "${MD}"; echo "- [ ] No unhandled high-sev alerts" >> "${MD}"; echo "- [ ] FS OK" >> "${MD}"; echo >> "${MD}"
if [[ -f "${SUMMARY}" ]]; then echo "## AI Self-Heal Summary" >> "${MD}"; echo >> "${MD}"; echo '```json' >> "${MD}"; sed -e 's/[[:cntrl:]]//g' "${SUMMARY}" | tail -n 2000 >> "${MD}"; echo '```' >> "${MD}"; echo >> "${MD}"; fi
for F in rkhunter chkrootkit; do echo "## ${F}" >> "${MD}"; echo >> "${MD}"; echo '```text' >> "${MD}"; sed -e 's/[[:cntrl:]]//g' "${OUT_DIR}/${F}.txt" | tail -n 500 >> "${MD}" || true; echo '```' >> "${MD}"; echo >> "${MD}"; done
echo "## Filesystem Audit" >> "${MD}"; echo >> "${MD}"; echo "- Full text: \`${FS_TXT}\`" >> "${MD}"; echo >> "${MD}"; echo '```text' >> "${MD}"; tail -n 300 "${FS_TXT}" >> "${MD}" || true; echo '```' >> "${MD}"
REPORT_SIGNING=$(grep -E '^report_signing=' /etc/cbw/ai-selfheal.conf | cut -d= -f2 || echo false)
if [[ "${REPORT_SIGNING}" == "true" ]] && command -v minisign >/dev/null 2>&1; then
  minisign -S -s /root/.minisign/cbw.key -m "${MD}" || true
fi
SH
  run "install -m 0755 /tmp/cbw-generate-security-report.$$ '${BIN_DIR}/cbw-generate-security-report' && rm -f /tmp/cbw-generate-security-report.$$"
  cat > /tmp/${SYSTEMD_UNIT_REPORT}.$$ <<UNIT
[Unit]
Description=CBW Daily Security Report
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
ExecStart=${BIN_DIR}/cbw-generate-security-report
User=root
Group=root
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
PrivateDevices=true
NoNewPrivileges=true
CapabilityBoundingSet=
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictRealtime=true
RestrictSUIDSGID=true
ReadWritePaths=/home /tmp
[Install]
WantedBy=multi-user.target
UNIT
  run "install -m 0644 /tmp/${SYSTEMD_UNIT_REPORT}.$$ /etc/systemd/system/${SYSTEMD_UNIT_REPORT} && rm -f /tmp/${SYSTEMD_UNIT_REPORT}.$$"
  cat > /tmp/${SYSTEMD_TIMER_REPORT}.$$ <<T
[Unit]
Description=Run CBW Daily Security Report at 03:17
[Timer]
OnCalendar=*-*-* 03:17:00
Persistent=true
Unit=${SYSTEMD_UNIT_REPORT}
[Install]
WantedBy=timers.target
T
  run "install -m 0644 /tmp/${SYSTEMD_TIMER_REPORT}.$$ /etc/systemd/system/${SYSTEMD_TIMER_REPORT} && rm -f /tmp/${SYSTEMD_TIMER_REPORT}.$$"
  run "systemctl daemon-reload"; run "systemctl enable --now ${SYSTEMD_TIMER_REPORT}"; }
install_exporter(){
  cat > /tmp/cbw-prom-eve-exporter.py.$$ <<'PY'
#!/usr/bin/env python3
import http.server, socketserver, json, os
PORT=9108; EVE=os.environ.get('CBW_EVE','/var/log/suricata/eve.json')
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path!='/metrics': self.send_error(404); return
        counts={'total':0,'alert':0,'alert_high':0}
        try:
            with open(EVE,'rb') as f:
                for ln in f.readlines()[-2000:]:
                    try:
                        j=json.loads(ln.decode('utf-8','ignore'))
                        counts['total']+=1
                        if j.get('event_type')=='alert':
                            counts['alert']+=1
                            if int(j.get('alert',{}).get('severity',0))>=2: counts['alert_high']+=1
                    except Exception: pass
        except Exception: pass
        out=(f"cbw_eve_total {counts['total']}\n"
             f"cbw_eve_alert {counts['alert']}\n"
             f"cbw_eve_alert_high {counts['alert_high']}\n")
        self.send_response(200); self.send_header('Content-Type','text/plain; version=0.0.4'); self.end_headers(); self.wfile.write(out.encode())
with socketserver.TCPServer(('',PORT), H) as httpd: httpd.serve_forever()
PY
  run "install -m 0755 /tmp/cbw-prom-eve-exporter.py.$$ '${BIN_DIR}/cbw-prom-eve-exporter.py' && rm -f /tmp/cbw-prom-eve-exporter.py.$$"
  cat > /tmp/${SYSTEMD_UNIT_EXPORTER}.$$ <<U
[Unit]
Description=CBW Prometheus EVE Exporter
After=suricata.service
[Service]
ExecStart=${BIN_DIR}/cbw-prom-eve-exporter.py
Environment=CBW_EVE=/var/log/suricata/eve.json
Restart=always
User=root
Group=root
ProtectSystem=strict
NoNewPrivileges=true
[Install]
WantedBy=multi-user.target
U
  run "install -m 0644 /tmp/${SYSTEMD_UNIT_EXPORTER}.$$ /etc/systemd/system/${SYSTEMD_UNIT_EXPORTER} && rm -f /tmp/${SYSTEMD_UNIT_EXPORTER}.$$"
  run "systemctl daemon-reload"; run "systemctl enable --now ${SYSTEMD_UNIT_EXPORTER}"; }
install_hardening(){
  cat > /tmp/99-cbw-hardening.conf.$$ <<'SYS'
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.all.accept_redirects=0
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
SYS
  run "install -m 0644 /tmp/99-cbw-hardening.conf.$$ /etc/sysctl.d/99-cbw-hardening.conf && rm -f /tmp/99-cbw-hardening.conf.$$"
  run "sysctl --system || true"; }
run_once(){ run "${SELFHEAL_PY} || true"; run "${BIN_DIR}/cbw-generate-security-report || true"; }
$INSTALL_ALL || $ONLY_IDS || $ONLY_SCANNERS || $ONLY_AGENT || INSTALL_ALL=true
log "Start ${SCRIPT_NAME}"
if $INSTALL_ALL || $ONLY_IDS; then install_suricata; install_snort; fi
if $INSTALL_ALL || $ONLY_SCANNERS; then install_scanners; fi
if $INSTALL_ALL || $ONLY_AGENT; then install_agent; install_reporting; fi
if $LOCALAI_ENABLED; then install_localai; fi
if $INSTALL_EXPORTERS; then install_exporter; fi
if $INSTALL_HARDENING; then install_hardening; fi
if $RUN_ONCE; then run_once; fi
log "Done."
