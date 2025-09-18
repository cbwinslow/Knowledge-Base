import Link from "next/link";

export default function Home() {
  return (
    <main className="grid md:grid-cols-2 gap-4">
      <Card href="/status" title="Status" desc="Health checks and metrics links" />
      <Card href="/moderation" title="Moderation" desc="Approve/hide comments and manage users" />
      <Card href="/exports" title="Exports" desc="Run NDJSON/CSV exports and view ETags/cursors" />
      <Card href="/settings" title="Settings" desc="JWT issuer/JWKS preview and rate limits" />
    </main>
  )
}

function Card({ href, title, desc }: any) {
  return (
    <Link href={href} className="block rounded-2xl p-4 bg-white shadow border hover:shadow-md transition">
      <div className="text-lg font-medium">{title}</div>
      <div className="text-sm text-slate-600">{desc}</div>
    </Link>
  )
}
