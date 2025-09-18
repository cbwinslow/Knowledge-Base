'use client'
import { useEffect, useMemo, useState } from 'react'
import { FileDown, Layers, Settings, Sparkles } from 'lucide-react'
import { listItems, semanticSearch } from '@/lib/data'
import { buildBash, buildAnsible } from '@/lib/exporters'
import type { ScriptItem } from '@/lib/types'
import { bundles } from '@/lib/bundles'
import ItemCard from '@/components/ItemCard'
import { Nav } from '@/components/Nav'
const API_BASE = process.env.NEXT_PUBLIC_STACKHUB_API || ''
export default function Home() {
  const [q, setQ] = useState('')
  const [mode, setMode] = useState<'bash'|'ansible'>('bash')
  const [items, setItems] = useState<ScriptItem[]>([])
  const [selected, setSelected] = useState<string[]>([])
  const [semantic, setSemantic] = useState(true)
  const [results, setResults] = useState<ScriptItem[]|null>(null)
  useEffect(() => { listItems().then(setItems).catch(console.error) }, [])
  useEffect(() => {
    let alive = true
    async function run(){ if(semantic && q.trim()){ try{ const r=await semanticSearch(q); if(alive) setResults(r)}catch(e){console.error(e); setResults(null)} } else setResults(null) }
    run(); return ()=>{alive=false}
  }, [q, semantic])
  const params = new URLSearchParams(typeof window !== 'undefined' ? window.location.search : '')
  const activeCat = params.get('cat') || ''
  const baseList = results ?? items
  const filtered = useMemo(() => {
    const qq = q.toLowerCase()
    return baseList.filter(i => (!activeCat || i.category===activeCat) && (results ? true : (i.name.toLowerCase().includes(qq) || i.category.toLowerCase().includes(qq) || i.tags.join(' ').toLowerCase().includes(qq))))
  }, [q, baseList, activeCat, results])
  const toggle = (id: string) => setSelected(prev => prev.includes(id) ? prev.filter(x => x!==id) : [...prev, id])
  const selectedItems = items.filter(i => selected.includes(i.id))
  const monolith = mode==='bash' ? buildBash(selectedItems) : buildAnsible(selectedItems)
  const applyBundle = (bundleId: string) => { const b=bundles.find(b=>b.id===bundleId); if(!b) return; setSelected(prev=>Array.from(new Set([...prev,...b.itemIds]))) }
  const ids = encodeURIComponent(selected.join(','))
  const localExportUrl = `/api/export?mode=${mode}&ids=${ids}`
  const edgeExportUrl = API_BASE ? `${API_BASE}/export?mode=${mode}&ids=${ids}` : localExportUrl
  const downloadHref = edgeExportUrl
  return (
    <div className="min-h-screen grid grid-cols-[280px_1fr]">
      <Nav q={q} setQ={setQ} />
      <main className="p-6 space-y-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3"><Layers /><h2 className="text-lg font-medium">Catalog</h2></div>
          <div className="flex items-center gap-2">
            <label className="text-sm opacity-80 flex items-center gap-1"><Sparkles size={14}/> Semantic <input type="checkbox" className="ml-1" checked={semantic} onChange={e=>setSemantic(e.target.checked)} /></label>
            <label className="text-sm opacity-80">Export:</label>
            <select value={mode} onChange={e=>setMode(e.target.value as any)} className="bg-neutral-900 border border-neutral-700 rounded px-2 py-1">
              <option value="bash">Bash</option><option value="ansible">Ansible</option>
            </select>
            <a href={downloadHref} className="inline-flex items-center gap-2 bg-green-700 hover:bg-green-600 px-3 py-1 rounded"><FileDown size={16}/> Download</a>
          </div>
        </div>
        <div className="flex gap-2 flex-wrap">{bundles.map(b => (<button key={b.id} onClick={()=>applyBundle(b.id)} className="text-xs border px-2 py-1 rounded border-neutral-700 hover:border-green-600">{b.name}</button>))}</div>
        <div className="grid md:grid-cols-2 gap-4">{filtered.map(i => (<ItemCard key={i.id} i={i} mode={mode} selected={selected.includes(i.id)} onToggle={toggle} />))}</div>
        <div className="border border-neutral-800 rounded p-3"><div className="flex items-center gap-2 mb-2"><Settings /><div className="font-medium">Monolith Preview</div></div>
          <pre className="code text-xs whitespace-pre-wrap bg-neutral-900 p-3 rounded max-h-[40vh] overflow-auto">{monolith}</pre>
        </div>
      </main>
    </div>
  )
}
