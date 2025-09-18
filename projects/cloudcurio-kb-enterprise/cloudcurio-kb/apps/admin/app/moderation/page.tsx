'use client'
import { useEffect, useState } from 'react'
const bff = process.env.NEXT_PUBLIC_BFF || 'http://localhost:8088'
export default function Moderation(){
  const [items, setItems] = useState<any[]>([])
  useEffect(()=>{ setItems([]) },[])
  return <div>
    <h2 className="text-xl font-medium mb-3">Moderation</h2>
    <p className="text-sm text-slate-600">Wire this to comments API once available.</p>
    <ul className="divide-y">
      {items.map((it,i)=><li key={i} className="py-2">{JSON.stringify(it)}</li>)}
    </ul>
  </div>
}
