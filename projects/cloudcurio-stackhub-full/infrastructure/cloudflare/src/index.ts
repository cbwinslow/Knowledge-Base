export interface Env {
  DB: D1Database
  VEC: VectorizeIndex
  AI: Ai
  ARTIFACTS: R2Bucket
  EMBED_QUEUE: Queue<any>
  CORS_ALLOW?: string
  REQUIRE_ACCESS?: string
  TURNSTILE_SECRET?: string
}
function corsHeaders(origin: string | null, allow?: string) { return { 'Access-Control-Allow-Origin': allow || origin || '*','Access-Control-Allow-Methods':'GET,POST,OPTIONS','Access-Control-Allow-Headers':'content-type, authorization, cf-turnstile-token', } }
function isPost(path: string, method: string) { return method === 'POST' && (path === '/items' || path === '/reindex') }
function accessEmail(req: Request) { return req.headers.get('Cf-Access-Authenticated-User-Email') }
async function verifyTurnstile(secret: string, token: string) {
  const r = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify',{method:'POST',body:new URLSearchParams({response:token,secret}),headers:{'content-type':'application/x-www-form-urlencoded'}})
  const data:any = await r.json(); if (!data.success) throw new Error('Turnstile failed')
}
function toItems(rows: any[]) { return rows.map((r:any)=>({ id:r.id,name:r.name,category:r.category,description:r.description,tags:String(r.tags||'').split(',').map((s:string)=>s.trim()).filter(Boolean),ports:String(r.ports||'').split(',').map((s:string)=>parseInt(s,10)).filter((n:number)=>!Number.isNaN(n)),script_bash:r.script_bash,script_ansible:r.script_ansible,terraform:r.terraform||undefined,pulumi:r.pulumi||undefined })) }
function buildBash(items: any[]) { const man = { created_at: new Date().toISOString(), items: items.map((i:any)=>({id:i.id,name:i.name,ports:i.ports||[]})) }; const header = `#!/usr/bin/env bash
set -Eeuo pipefail
LOG_FILE="/tmp/CBW-stackhub.log"; exec > >(tee -a "$LOG_FILE") 2>&1
trap 'echo "[ERROR] at line $LINENO"' ERR
echo "[INFO] Start $(date)"`; const manifest = `# MANIFEST
cat >/tmp/stackhub.manifest.json <<'JSON'
${JSON.stringify(man,null,2)}
JSON`; const parts=[header,manifest]; for(const it of items){ parts.push(`### BEGIN: ${it.name}`); parts.push(it.script_bash.trim()); parts.push(`### END: ${it.name}\n`) } parts.push('echo "[INFO] Export complete"'); return parts.join('\n') }
function buildAnsible(items: any[]) { const tasks = items.map((it:any)=>`  - name: ${it.name}
    become: true
    ansible.builtin.shell: |
${it.script_bash.split('\n').map((l:string)=>'      '+l).join('\n')}
`).join('\n'); return `---
- name: CloudCurio StackHub Monolith
  hosts: all
  gather_facts: true
  become: true
  vars: { ansible_python_interpreter: /usr/bin/python3 }
  tasks:
${tasks}` }
async function sha256Hex(s: string) { const b=new TextEncoder().encode(s); const d=await crypto.subtle.digest('SHA-256', b); return Array.from(new Uint8Array(d)).map(x=>x.toString(16).padStart(2,'0')).join('') }
export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url); const origin = req.headers.get('origin'); const headers = corsHeaders(origin, env.CORS_ALLOW); if (req.method === 'OPTIONS') return new Response(null, { headers })
    if (env.REQUIRE_ACCESS && isPost(url.pathname, req.method)) { const email = accessEmail(req); if (!email) return new Response('Unauthorized (Access required)', { status: 401, headers }) }
    if (env.TURNSTILE_SECRET && isPost(url.pathname, req.method)) { const token = req.headers.get('cf-turnstile-token') || ''; if (!token) return new Response('Turnstile token missing', { status: 400, headers }); try { await verifyTurnstile(env.TURNSTILE_SECRET, token) } catch { return new Response('Turnstile failed', { status: 400, headers }) } }
    if (url.pathname === '/items' && req.method === 'GET') { const { results } = await env.DB.prepare('SELECT * FROM items').all(); return new Response(JSON.stringify({ items: toItems(results) }), { headers, status: 200 }) }
    if (url.pathname === '/items' && req.method === 'POST') {
      const body = await req.json()
      await env.DB.prepare(`INSERT OR REPLACE INTO items (id,name,category,description,tags,ports,script_bash,script_ansible,terraform,pulumi) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10)`)
        .bind(body.id, body.name, body.category, body.description, (body.tags||[]).join(','), (body.ports||[]).join(','), body.script_bash, body.script_ansible, body.terraform||null, body.pulumi||null).run()
      if (env.EMBED_QUEUE) { await env.EMBED_QUEUE.send({ id: body.id, name: body.name, category: body.category, tags: (body.tags||[]).join(','), description: body.description, script_bash: body.script_bash }) }
      return new Response(JSON.stringify({ ok:true, queued: !!env.EMBED_QUEUE }), { headers, status: 200 })
    }
    if (url.pathname === '/reindex' && req.method === 'POST') {
      const { results } = await env.DB.prepare('SELECT * FROM items').all()
      const batches: any[] = []
      for (const r of results as any[]) {
        const text = `${r.name}\n${r.category}\n${r.tags}\n${r.description}\n${r.script_bash}`
        const res: any = await env.AI.run('@cf/baai/bge-base-en-v1.5', { text })
        const vector = Array.isArray(res?.data?.[0]) ? res.data[0] : (res?.data || [])
        batches.push({ id: r.id, values: vector, metadata: { name: r.name, category: r.category } })
      }
      const CHUNK = 64; for (let i=0;i<batches.length;i+=CHUNK) await env.VEC.upsert(batches.slice(i,i+CHUNK))
      return new Response(JSON.stringify({ ok:true, count:batches.length }), { headers, status: 200 })
    }
    if (url.pathname === '/search' && req.method === 'GET') {
      const q = url.searchParams.get('q') || ''
      if (!q) return new Response(JSON.stringify({ items: [] }), { headers, status: 200 })
      const res: any = await env.AI.run('@cf/baai/bge-base-en-v1.5', { text: q })
      const qvec = Array.isArray(res?.data?.[0]) ? res.data[0] : (res?.data || [])
      const results = await env.VEC.query(qvec, { topK:20, includeMetadata:true })
      const ids = results.matches?.map((m:any)=>m.id) || []
      if (ids.length === 0) return new Response(JSON.stringify({ items: [] }), { headers, status: 200 })
      const placeholders = ids.map(()=>'?').join(',')
      const { results: rows } = await env.DB.prepare(`SELECT * FROM items WHERE id IN (${placeholders})`).bind(...ids).all()
      const items = toItems(rows)
      const order = new Map(ids.map((id:string,idx:number)=>[id,idx])); items.sort((a,b)=> (order.get(a.id)??0) - (order.get(b.id)??0))
      return new Response(JSON.stringify({ items }), { headers, status: 200 })
    }
    if (url.pathname === '/export' && req.method === 'GET') {
      const ids = (url.searchParams.get('ids') || '').split(',').filter(Boolean)
      const mode = (url.searchParams.get('mode') || 'bash')
      if (ids.length === 0) return new Response('No ids', { status: 400, headers })
      const placeholders = ids.map(()=>'?').join(',')
      const { results: rows } = await env.DB.prepare(`SELECT * FROM items WHERE id IN (${placeholders})`).bind(...ids).all()
      const items = toItems(rows)
      const content = (mode==='ansible') ? buildAnsible(items) : buildBash(items)
      const hash = await sha256Hex(JSON.stringify({ mode, items }))
      const ext = mode==='ansible' ? 'yml' : 'sh'
      const key = `exports/${hash}.${ext}`
      try { const head = await env.ARTIFACTS.head(key); if (!head) await env.ARTIFACTS.put(key, content, { httpMetadata: { contentType: 'text/plain; charset=utf-8' } }) } catch {}
      const cacheKey = new Request(`https://cache/export/${hash}`)
      let res = await caches.default.match(cacheKey)
      if (!res) {
        res = new Response(content, { headers: { ...headers,'content-type':'text/plain; charset=utf-8','cache-tag': hash,'x-export-hash': hash,'x-share-url': `/share/${hash}`,'content-disposition': `attachment; filename=stackhub-export.${ext}`, }})
        await caches.default.put(cacheKey, res.clone())
      }
      return res
    }
    if (url.pathname.startsWith('/share/')) {
      const hash = url.pathname.split('/').pop() || ''
      const tryKeys = [`exports/${hash}.sh`, `exports/${hash}.yml`]
      for (const key of tryKeys) {
        const obj = await env.ARTIFACTS.get(key)
        if (obj) return new Response(obj.body, { headers: { 'content-type':'text/plain; charset=utf-8','x-export-hash': hash } })
      }
      return new Response('Not found', { status: 404, headers })
    }
    return new Response('Not found', { status: 404, headers })
  },
  async queue(batch: MessageBatch<any>, env: Env) {
    for (const msg of batch.messages) {
      const b = msg.body
      try {
        const text = `${b.name}\n${b.category}\n${b.tags}\n${b.description}\n${b.script_bash}`
        const res: any = await env.AI.run('@cf/baai/bge-base-en-v1.5', { text })
        const vector = Array.isArray(res?.data?.[0]) ? res.data[0] : (res?.data || [])
        await env.VEC.upsert([{ id: b.id, values: vector, metadata: { name: b.name, category: b.category } }])
        msg.ack()
      } catch { msg.retry() }
    }
  }
}
