import { listProfiles } from '@/lib/api'
import Card from '@/components/Card'
import Link from 'next/link'

export const dynamic = 'force-dynamic'

export default async function Page() {
  const profiles = await listProfiles()
  return (
    <div className="space-y-4">
      <h1 className="text-xl font-semibold">Profiles</h1>
      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
        {profiles.map(p => (
          <Card key={p.id}>
            <div className="flex items-center justify-between">
              <div>
                <div className="text-matrix font-semibold">{p.name}</div>
                <div className="text-xs text-neutral-400">{p.category}</div>
              </div>
              <Link className="link" href={`/profiles/${p.id}`}>View</Link>
            </div>
          </Card>
        ))}
      </div>
    </div>
  )
}
