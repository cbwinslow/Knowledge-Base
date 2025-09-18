'use client'
import { useEffect, useState } from 'react'

export default function Settings(){
  const [issuer,setIssuer]=useState(process.env.NEXT_PUBLIC_ISSUER||'')
  const [jwks,setJwks]=useState<any>(null)
  useEffect(()=>{ (async()=>{
    if(!issuer) return
    try{
      const r=await fetch(issuer.replace(/\/$/,'')+'/protocol/openid-connect/certs')
      setJwks(await r.json())
    }catch(e:any){ setJwks({error:e.message}) }
  })() },[issuer])
  return <div className="space-y-3">
    <label className="block">
      <div className="text-sm">Issuer</div>
      <input value={issuer} onChange={e=>setIssuer(e.target.value)} className="border rounded px-2 py-1 w-full"/>
    </label>
    <pre className="bg-slate-100 p-3 rounded text-xs">{JSON.stringify(jwks,null,2)}</pre>
  </div>
}
