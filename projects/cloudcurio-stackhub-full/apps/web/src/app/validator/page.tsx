'use client'
import { useEffect, useMemo, useState } from 'react'
import { AlertTriangle } from 'lucide-react'
import { listItems } from '@/lib/data'
import type { ScriptItem } from '@/lib/types'
export default function Validator(){
  const [items,setItems]=useState<ScriptItem[]>([]); const [selected,setSelected]=useState<string[]>([])
  useEffect(()=>{ listItems().then(setItems).catch(console.error) }, [])
  const selectedItems = items.filter(i=>selected.includes(i.id))
  const portsMap: Record<number,string[]> = {}
  selectedItems.forEach(i => (i.ports||[]).forEach(p => { portsMap[p]=portsMap[p]||[]; portsMap[p].push(i.name) }))
  const collisions = useMemo(()=> Object.entries(portsMap).filter(([_,v])=>v.length>1), [portsMap])
  return (
    <div className="p-6">
      <h2 className="text-lg font-medium mb-3">Port Collision Validator</h2>
      <p className="text-sm opacity-80 mb-4">Select items to check for port conflicts before exporting.</p>
      <div className="grid md:grid-cols-2 gap-2 mb-6">
        {items.map(i => (
          <label key={i.id} className="flex items-center gap-2 border border-neutral-800 rounded px-2 py-1">
            <input type="checkbox" checked={selected.includes(i.id)} onChange={()=> setSelected(prev=> prev.includes(i.id)? prev.filter(x=>x!==i.id) : [...prev,i.id])} />
            <span>{i.name}</span>
            {i.ports && i.ports.length>0 && (<span className="text-xs opacity-70 ml-auto">ports: {i.ports.join(', ')}</span>)}
          </label>
        ))}
      </div>
      {collisions.length>0 ? (
        <div className="border border-red-800 bg-red-950/40 rounded p-3">
          <div className="flex items-center gap-2 mb-2 text-red-300"><AlertTriangle/> Conflicts</div>
          <ul className="text-sm">{collisions.map(([port,names]) => (<li key={port}>Port {port}: {names.join(', ')}</li>))}</ul>
          <p className="text-xs opacity-70 mt-2">Suggestion: remap container `ports:` or pick alternatives, then export.</p>
        </div>
      ) : (<div className="text-sm opacity-80">No conflicts detected.</div>)}
    </div>
  )
}
