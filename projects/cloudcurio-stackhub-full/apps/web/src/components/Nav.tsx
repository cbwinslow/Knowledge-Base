'use client'
import { Library, Search } from 'lucide-react'
import { usePathname, useRouter } from 'next/navigation'
import { useState } from 'react'
const CATS = ['system','security','networking','docker','ansible','terraform','pulumi','ai','databases','monitoring']
export function Nav({ q, setQ }: { q: string; setQ: (v: string)=>void }) {
  const pathname = usePathname(); const router = useRouter(); const [cat,setCat]=useState('')
  return (
    <aside className="border-r border-neutral-800 p-4 min-h-screen">
      <div className="flex items-center gap-2 mb-4"><Library /><h1 className="text-xl font-semibold">StackHub</h1></div>
      <div className="space-y-3">
        <div className="flex items-center gap-2 rounded bg-neutral-900 px-2 py-1">
          <Search className="shrink-0" />
          <input value={q} onChange={e=>setQ(e.target.value)} placeholder="Search..." className="bg-transparent outline-none w-full" />
        </div>
        <div className="text-sm text-neutral-300">
          <div className="uppercase text-neutral-400 tracking-widest mb-2">Categories</div>
          <div className="space-y-1">
            {CATS.map(c => (
              <button key={c} onClick={()=>{ setCat(c===cat?'':c); const s=new URLSearchParams(window.location.search); if(c===cat) s.delete('cat'); else s.set('cat',c); router.push(`/?${s.toString()}`) }} className={`block w-full text-left py-1 rounded px-2 hover:bg-neutral-900 ${cat===c?'bg-neutral-900':''}`}>{c}</button>
            ))}
          </div>
        </div>
        <div className="mt-6 text-sm space-y-1">
          <a href="/" className={`block px-2 py-1 rounded hover:bg-neutral-900 ${pathname==='/'?'bg-neutral-900':''}`}>Catalog</a>
          <a href="/validator" className={`block px-2 py-1 rounded hover:bg-neutral-900 ${pathname?.startsWith('/validator')?'bg-neutral-900':''}`}>Port Validator</a>
          <a href="/admin" className={`block px-2 py-1 rounded hover:bg-neutral-900 ${pathname?.startsWith('/admin')?'bg-neutral-900':''}`}>Admin</a>
        </div>
      </div>
    </aside>
  )
}
