'use client'
import { useEffect, useState } from 'react'
import type { ScriptItem } from '@/lib/types'
import { listItems } from '@/lib/data'
export default function Admin(){
  const [items,setItems]=useState<ScriptItem[]>([]); const [msg,setMsg]=useState('')
  useEffect(()=>{ listItems().then(setItems).catch(console.error) }, [])
  async function saveNewItem(e:any){ e.preventDefault(); const form=new FormData(e.currentTarget); const body=Object.fromEntries(form.entries())
    try{
      const r=await fetch(`${process.env.NEXT_PUBLIC_STACKHUB_API || ''}/items`,{
        method:'POST',
        headers:{'Content-Type':'application/json', 'cf-turnstile-token': (document.getElementById('turnstile-token') as HTMLInputElement)?.value || ''},
        body:JSON.stringify({
          id:body.id, name:body.name, category:body.category, description:body.description,
          tags:String(body.tags||'').split(',').map(s=>s.trim()).filter(Boolean),
          ports:String(body.ports||'').split(',').map(s=>parseInt(String(s).trim(),10)).filter(n=>!Number.isNaN(n)),
          script_bash:body.script_bash, script_ansible:body.script_ansible, terraform:body.terraform||undefined, pulumi:body.pulumi||undefined,
        })
      })
      if(!r.ok) throw new Error('Save failed'); setMsg('Saved! It may take a moment to index (Queue).')
    }catch(e:any){ setMsg('Error: '+e.message) }
  }
  return (
    <div className="p-6 max-w-4xl">
      <h2 className="text-lg font-medium mb-3">Admin / Editor</h2>
      <p className="text-sm opacity-80 mb-4">When D1 + Worker API are enabled, you can add items here.</p>
      <form onSubmit={saveNewItem} className="grid gap-2">
        <input name="id" placeholder="id (unique)" className="bg-neutral-900 px-2 py-1 rounded" required />
        <input name="name" placeholder="name" className="bg-neutral-900 px-2 py-1 rounded" required />
        <input name="category" placeholder="category" className="bg-neutral-900 px-2 py-1 rounded" required />
        <input name="tags" placeholder="tags (comma-separated)" className="bg-neutral-900 px-2 py-1 rounded" />
        <input name="ports" placeholder="ports (comma-separated)" className="bg-neutral-900 px-2 py-1 rounded" />
        <textarea name="description" placeholder="description" className="bg-neutral-900 px-2 py-1 rounded" rows={2}></textarea>
        <textarea name="script_bash" placeholder="script_bash" className="bg-neutral-900 px-2 py-1 rounded" rows={6}></textarea>
        <textarea name="script_ansible" placeholder="script_ansible" className="bg-neutral-900 px-2 py-1 rounded" rows={6}></textarea>
        <textarea name="terraform" placeholder="terraform (optional)" className="bg-neutral-900 px-2 py-1 rounded" rows={4}></textarea>
        <textarea name="pulumi" placeholder="pulumi (optional)" className="bg-neutral-900 px-2 py-1 rounded" rows={4}></textarea>
        <input id="turnstile-token" hidden />
        <button className="mt-2 bg-green-700 hover:bg-green-600 px-3 py-1 rounded w-fit">Save Item</button>
        {msg && <div className="text-sm opacity-80">{msg}</div>}
      </form>
      <div className="mt-8">
        <h3 className="font-medium mb-2">Current (seed) items</h3>
        <ul className="text-sm opacity-80 list-disc ml-6">{items.map(i=> <li key={i.id}>{i.id} — {i.name}</li>)}</ul>
      </div>
    </div>
  )
}
