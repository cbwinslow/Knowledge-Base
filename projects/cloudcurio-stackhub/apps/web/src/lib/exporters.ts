// Utility to synthesize monoliths on the client for preview.
import type { ScriptItem } from './types'

const SHELL_HEADER = `#!/usr/bin/env bash
set -Eeuo pipefail
LOG_FILE="/tmp/CBW-stackhub.log"
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'echo "[ERROR] at line $LINENO"' ERR
echo "[INFO] Starting export $(date)"
`

export function buildBash(items: ScriptItem[]) {
  const parts = [SHELL_HEADER]
  for (const it of items) {
    parts.push(`### BEGIN: ${it.name}`)
    parts.push(it.script_bash.trim())
    parts.push(`### END: ${it.name}\n`)
  }
  parts.push('echo "[INFO] Export complete"')
  return parts.join('\n')
}

export function buildAnsible(items: ScriptItem[]) {
  const tasks = items.map((it, idx) => `  - name: ${it.name}
    become: true
    ansible.builtin.shell: |
${it.script_bash.split('\n').map(l => '      ' + l).join('\n')}
`).join('\n')

  return `---
- name: CloudCurio StackHub Monolith
  hosts: all
  gather_facts: true
  become: true
  vars:
    ansible_python_interpreter: /usr/bin/python3
  tasks:
${tasks}`
}
