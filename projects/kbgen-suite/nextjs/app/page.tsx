"use client";
import { useState } from "react";

export default function Home() {
  const [root, setRoot] = useState("https://example.com/docs/");
  const [domain, setDomain] = useState("example.com");
  const [keywords, setKeywords] = useState("install,api,usage");
  const [stdout, setStdout] = useState("");
  const API = process.env.NEXT_PUBLIC_API_BASE || "http://localhost:5055";

  async function submit() {
    const cfg = {
      objective: "Docs",
      tags: ["docs"],
      method: "bfs",
      targets: { bfs_roots: [root], sitemaps:[], rss_feeds:[], urls:[] },
      rules: {
        allowed_domains: [domain],
        exclude_patterns: ["\\.pdf$"],
        keywords: keywords.split(",").map(s=>s.trim()),
        obey_robots: true, max_pages: 30, max_depth: 3, concurrency: 5, rate_limit: 0.2,
        user_agent: "CBW-KBGen/0.2"
      },
      output: { out_dir: "kb_output", compiled_name: "KB" },
      storage: { vector: "qdrant", sql: "sqlite", sqlite_path: "kb.sqlite" },
      embeddings: { provider: "sbert", model: "sentence-transformers/all-MiniLM-L6-v2", chunk_tokens: 500, chunk_overlap: 50 },
      dry_run: false, verbose: false
    };
    const res = await fetch(`${API}/run`, { method: "POST", headers: {"Content-Type":"application/json"}, body: JSON.stringify({ config: cfg })});
    const j = await res.json();
    setStdout(j.stdout || JSON.stringify(j,null,2));
  }

  return (
    <main className="p-6 max-w-3xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">KBGen Dashboard</h1>
      <label className="block mb-2">Root URL</label>
      <input className="w-full border p-2 mb-4" value={root} onChange={e=>setRoot(e.target.value)} />
      <label className="block mb-2">Allowed Domain</label>
      <input className="w-full border p-2 mb-4" value={domain} onChange={e=>setDomain(e.target.value)} />
      <label className="block mb-2">Keywords (comma separated)</label>
      <input className="w-full border p-2 mb-4" value={keywords} onChange={e=>setKeywords(e.target.value)} />
      <button onClick={submit} className="px-4 py-2 rounded bg-black text-white">Run Crawl</button>
      <pre className="mt-6 p-4 bg-gray-100 overflow-auto text-sm">{stdout}</pre>
    </main>
  );
}
