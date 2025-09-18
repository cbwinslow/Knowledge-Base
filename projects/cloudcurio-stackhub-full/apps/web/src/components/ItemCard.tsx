'use client'
import { useState } from 'react'
import type { ScriptItem } from '@/lib/types'
export default function ItemCard({ i, mode, selected, onToggle }:{ i: ScriptItem; mode:'bash'|'ansible'; selected:boolean; onToggle:(id:string)=>void }){
  const [open,setOpen]=useState(false); const preview=mode==='bash'?i.script_bash:i.script_ansible
  return (
    <div className={`border rounded border-neutral-800 p-3 bg-neutral-950/50 ${selected?'ring-1 ring-green-500':''}`}>
      <div className="flex items-center justify-between"><div className="font-medium">{i.name}</div>
        <button onClick={()=>onToggle(i.id)} className="text-xs border px-2 py-1 rounded border-neutral-700 hover:border-green-600">{selected?'Remove':'Add'}</button>
      </div>
      <div className="text-xs text-neutral-400">{i.category}</div>
      <p className="text-sm mt-2">{i.description}</p>
      <div className="mt-3 text-xs text-neutral-300"><span className="opacity-60">Tags:</span> {i.tags.join(', ')}</div>
      <details className="mt-3" open={open} onToggle={()=>setOpen(v=>!v)}>
        <summary className="cursor-pointer text-sm">Preview</summary>
        <pre className="code text-xs p-2 bg-neutral-900 rounded mt-2 overflow-x-auto whitespace-pre-wrap">{preview}</pre>
      </details>
    </div>
  )
}
