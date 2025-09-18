"use client";
import { useState } from "react";

export default function SearchPage(){
  const [q, setQ] = useState("");
  const [res, setRes] = useState<any>(null);
  const API = process.env.NEXT_PUBLIC_API_BASE || "http://localhost:5055";

  async function go(){
    const r = await fetch(`${API}/search`, {method:"POST", headers:{"Content-Type":"application/json"}, body: JSON.stringify({query:q, top_k:10})});
    const j = await r.json();
    setRes(j);
  }

  return (
    <main className="p-6 max-w-3xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">KB Search</h1>
      <input className="border p-2 w-full mb-2" value={q} onChange={e=>setQ(e.target.value)} placeholder="Search query"/>
      <button onClick={go} className="px-4 py-2 rounded bg-black text-white">Search</button>
      <div className="mt-6 space-y-3">
        {res?.results?.map((r:any, i:number)=> (
          <div key={i} className="border p-3 rounded">
            <div className="text-sm text-gray-500">score: {r.score?.toFixed(3)}</div>
            <div className="font-semibold">{r.title}</div>
            <a className="text-blue-600 underline" href={r.url} target="_blank">{r.url}</a>
          </div>
        ))}
      </div>
    </main>
  );
}
