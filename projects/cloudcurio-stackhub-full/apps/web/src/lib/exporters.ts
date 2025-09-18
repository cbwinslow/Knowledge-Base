import type { ScriptItem } from './types'
const SHELL_HEADER = `#!/usr/bin/env bash
set -Eeuo pipefail
LOG_FILE="/tmp/CBW-stackhub.log"; exec > >(tee -a "$LOG_FILE") 2>&1
trap 'echo "[ERROR] at line $LINENO"' ERR
DRYRUN="${DRYRUN:-0}"
_preflight(){ echo "[INFO] Preflight checks..."; command -v bash>/dev/null||{echo "bash missing"; exit 1}; command -v curl>/dev/null||echo "[WARN] curl not found" }
_run(){ if [ "$DRYRUN" = "1" ]; then echo "> DRYRUN: $*"; return 0; fi; eval "$@"; }
echo "[INFO] Starting export $(date)"; _preflight
`
export function buildBash(items: ScriptItem[]) {
  const manifest = { created_at: new Date().toISOString(), items: items.map(i=>({id:i.id,name:i.name,ports:i.ports||[]})) }
  const manifestBlock = `# MANIFEST JSON
cat > /tmp/stackhub.manifest.json <<'JSON'
${JSON.stringify(manifest,null,2)}
JSON
`
  const parts = [SHELL_HEADER, manifestBlock]
  for (const it of items){ parts.push(`### BEGIN: ${it.name}`); parts.push(it.script_bash.trim()); parts.push(`### END: ${it.name}\n`) }
  parts.push('echo "[INFO] Export complete"'); return parts.join('\n')
}
export function buildAnsible(items: ScriptItem[]) {
  const tasks = items.map(it => `  - name: ${it.name}
    become: true
    ansible.builtin.shell: |
${it.script_bash.split('\n').map(l => '      ' + l).join('\n')}
`).join('\n')
  return `---
- name: CloudCurio StackHub Monolith
  hosts: all
  gather_facts: true
  become: true
  vars: { ansible_python_interpreter: /usr/bin/python3 }
  tasks:
${tasks}`
}
