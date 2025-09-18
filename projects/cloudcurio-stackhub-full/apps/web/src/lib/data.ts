import type { ScriptItem } from './types'
import seed from './seed.json'
const USE_WORKER_API = true
const API_BASE = process.env.NEXT_PUBLIC_STACKHUB_API || ''
export async function listItems(): Promise<ScriptItem[]> {
  if (!USE_WORKER_API || !API_BASE) return seed.items as ScriptItem[]
  const r = await fetch(`${API_BASE}/items`); if(!r.ok) throw new Error('Failed to fetch items')
  const data = await r.json(); return data.items as ScriptItem[]
}
export async function semanticSearch(q: string): Promise<ScriptItem[]> {
  if (!USE_WORKER_API || !API_BASE) return (seed.items as ScriptItem[]).filter(i =>
    i.name.toLowerCase().includes(q.toLowerCase()) ||
    i.category.toLowerCase().includes(q.toLowerCase()) ||
    i.tags.join(' ').toLowerCase().includes(q.toLowerCase())
  )
  const r = await fetch(`${API_BASE}/search?q=${encodeURIComponent(q)}`); if(!r.ok) throw new Error('Search failed')
  const data = await r.json(); return data.items as ScriptItem[]
}
