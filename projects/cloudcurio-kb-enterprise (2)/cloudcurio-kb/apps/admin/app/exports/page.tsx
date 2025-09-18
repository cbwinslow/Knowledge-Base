'use client'
import { useState } from 'react'

export default function Exports() {
  const [kind, setKind] = useState('documents')
  const [format, setFormat] = useState('ndjson')
  const [cursor, setCursor] = useState('')
  const [etag, setEtag] = useState('')
  const bff = process.env.NEXT_PUBLIC_BFF || 'http://localhost:8088'

  async function run() {
    const r = await fetch(`${bff}/v1/export?kind=${kind}&format=${format}&cursor=${cursor}&page_size=1000`, {
      headers: { ...authHeaders(), 'Accept': 'application/x-ndjson' }
    })
    setEtag(r.headers.get('etag') || '')
    const blob = await r.blob()
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${kind}.${format === 'ndjson' ? 'ndjson' : format}`
    a.click()
    URL.revokeObjectURL(url)
  }

  return <div className="space-y-4">
    <h2 className="text-xl font-medium">Exports</h2>
    <div className="grid md:grid-cols-3 gap-4">
      <Select label="Kind" value={kind} onChange={setKind} opts={['documents','entities','relations']} />
      <Select label="Format" value={format} onChange={setFormat} opts={['ndjson','csv','parquet']} />
      <Field label="Cursor" value={cursor} onChange={setCursor} placeholder="0 or last cursor" />
    </div>
    <button onClick={run} className="rounded px-4 py-2 bg-black text-white hover:bg-slate-800">Run export</button>
    {etag ? <div className="text-sm text-slate-600">ETag: <code>{etag}</code></div> : null}
  </div>
}

function Field({label,value,onChange,placeholder}:any){
  return <label className="block">
    <div className="text-sm">{label}</div>
    <input value={value} onChange={e=>onChange(e.target.value)} placeholder={placeholder}
      className="w-full border rounded px-2 py-1"/>
  </label>
}
function Select({label,value,onChange,opts}:any){
  return <label className="block">
    <div className="text-sm">{label}</div>
    <select value={value} onChange={e=>onChange(e.target.value)} className="w-full border rounded px-2 py-1">
      {opts.map((o:string)=><option key={o} value={o}>{o}</option>)}
    </select>
  </label>
}

function authHeaders() {
  const t = localStorage.getItem('jwt') || ''
  return { 'Authorization': 'Bearer ' + t }
}
