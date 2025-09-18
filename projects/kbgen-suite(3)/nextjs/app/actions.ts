"use server";
export async function runCrawl(config: any) {
  const base = process.env.NEXT_PUBLIC_API_BASE!;
  const res = await fetch(`${base}/run`, {
    method: "POST",
    headers: {"Content-Type":"application/json"},
    body: JSON.stringify({ config }),
    cache: "no-store",
  });
  if (!res.ok) throw new Error(`API failed: ${res.status}`);
  return res.json();
}
