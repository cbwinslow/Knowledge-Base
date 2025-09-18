'use client'
import { useEffect, useState } from 'react'

export default function Status() {
  const [status, setStatus] = useState<any>(null)
  const bff = process.env.NEXT_PUBLIC_BFF || 'http://localhost:8088'
  useEffect(() => {
    (async () => {
      try {
        const r = await fetch(bff + '/v1/search?q=ping&top_k=1', { headers: authHeaders() })
        setStatus({ ok: r.ok, code: r.status })
      } catch (e:any) { setStatus({ ok:false, error: e.message }) }
    })()
  }, [])
  return <div className="space-y-3">
    <h2 className="text-xl font-medium">BFF Status</h2>
    <pre className="bg-slate-100 p-3 rounded">{JSON.stringify(status, null, 2)}</pre>
    <ul className="list-disc pl-6">
      <li><a className="underline" href="/grafana" target="_blank">Grafana</a></li>
      <li><a className="underline" href="/prometheus" target="_blank">Prometheus</a></li>
    </ul>
  </div>
}

function authHeaders() {
  const t = localStorage.getItem('jwt') || ''
  return { 'Authorization': 'Bearer ' + t }
}
