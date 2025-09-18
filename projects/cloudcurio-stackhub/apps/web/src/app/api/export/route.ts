import { NextRequest, NextResponse } from 'next/server'
import seed from '@/lib/seed.json'
import { buildAnsible, buildBash } from '@/lib/exporters'

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url)
  const ids = (searchParams.get('ids') || '').split(',').filter(Boolean)
  const mode = (searchParams.get('mode') || 'bash') as 'bash'|'ansible'
  const items = seed.items.filter(i => ids.includes(i.id))

  const content = mode === 'bash' ? buildBash(items as any) : buildAnsible(items as any)
  const filename = mode === 'bash' ? 'stackhub-export.sh' : 'stackhub-export.yml'
  return new NextResponse(content, {
    headers: {
      'Content-Type': 'text/plain; charset=utf-8',
      'Content-Disposition': `attachment; filename=${filename}`
    }
  })
}
