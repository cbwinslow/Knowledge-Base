'use client'

import { useMemo, useState } from 'react'
import { Library, Search, FileDown, Rocket, Filter, Layers, Settings } from 'lucide-react'
import seed from '@/lib/seed.json'
import { buildBash, buildAnsible } from '@/lib/exporters'

type Item = typeof seed.items[number]

export default function Home() {
  const [q, setQ] = useState('')
  const [selected, setSelected] = useState<string[]>([])
  const [mode, setMode] = useState<'bash'|'ansible'>('bash')

  const items: Item[] = seed.items

  const filtered = useMemo(() => {
    const qq = q.toLowerCase()
    return items.filter(i => 
      i.name.toLowerCase().includes(qq) ||
      i.category.toLowerCase().includes(qq) ||
      i.tags.join(' ').toLowerCase().includes(qq)
    )
  }, [q, items])

  const toggle = (id: string) => {
    setSelected(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id])
  }

  const selectedItems = items.filter(i => selected.includes(i.id))

  const monolith = mode === 'bash' ? buildBash(selectedItems) : buildAnsible(selectedItems)

  return (
    <div className="min-h-screen grid grid-cols-[280px_1fr]">
      <aside className="border-r border-neutral-800 p-4">
        <div className="flex items-center gap-2 mb-4">
          <Library />
          <h1 className="text-xl font-semibold">StackHub</h1>
        </div>
        <div className="space-y-3">
          <div className="flex items-center gap-2 rounded bg-neutral-900 px-2 py-1">
            <Search className="shrink-0" />
            <input
              value={q}
              onChange={e => setQ(e.target.value)}
              placeholder="Search..."
              className="bg-transparent outline-none w-full"
            />
          </div>
          <div className="text-sm text-neutral-300">
            <div className="uppercase text-neutral-400 tracking-widest mb-2">Categories</div>
            {['system','security','networking','docker','ansible','terraform','pulumi','ai','databases','monitoring'].map(c => (
              <div key={c} className="py-1">{c}</div>
            ))}
          </div>
        </div>
      </aside>

      <main className="p-6 space-y-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Layers />
            <h2 className="text-lg font-medium">Catalog</h2>
          </div>
          <div className="flex items-center gap-2">
            <label className="text-sm opacity-80">Export:</label>
            <select
              value={mode}
              onChange={e => setMode(e.target.value as any)}
              className="bg-neutral-900 border border-neutral-700 rounded px-2 py-1"
            >
              <option value="bash">Bash</option>
              <option value="ansible">Ansible</option>
            </select>
            <a
              href={`/api/export?mode=${mode}&ids=${encodeURIComponent(selected.join(','))}`}
              className="inline-flex items-center gap-2 bg-green-700 hover:bg-green-600 px-3 py-1 rounded"
            >
              <FileDown size={16}/> Download
            </a>
          </div>
        </div>

        <div className="grid md:grid-cols-2 gap-4">
          {filtered.map(i => (
            <div key={i.id} className={`border rounded border-neutral-800 p-3 bg-neutral-950/50 ${selected.includes(i.id) ? 'ring-1 ring-green-500' : ''}`}>
              <div className="flex items-center justify-between">
                <div className="font-medium">{i.name}</div>
                <button onClick={() => toggle(i.id)} className="text-xs border px-2 py-1 rounded border-neutral-700 hover:border-green-600">
                  {selected.includes(i.id) ? 'Remove' : 'Add'}
                </button>
              </div>
              <div className="text-xs text-neutral-400">{i.category}</div>
              <p className="text-sm mt-2">{i.description}</p>
              <div className="mt-3 text-xs text-neutral-300">
                <span className="opacity-60">Tags:</span> {i.tags.join(', ')}
              </div>
              <details className="mt-3">
                <summary className="cursor-pointer text-sm">Preview</summary>
                <pre className="code text-xs p-2 bg-neutral-900 rounded mt-2 overflow-x-auto">{mode === 'bash' ? i.script_bash : i.script_ansible}</pre>
              </details>
            </div>
          ))}
        </div>

        <div className="border border-neutral-800 rounded p-3">
          <div className="flex items-center gap-2 mb-2">
            <Settings />
            <div className="font-medium">Monolith Preview</div>
          </div>
          <pre className="code text-xs whitespace-pre-wrap bg-neutral-900 p-3 rounded max-h-[40vh] overflow-auto">{monolith}</pre>
        </div>
      </main>
    </div>
  )
}
