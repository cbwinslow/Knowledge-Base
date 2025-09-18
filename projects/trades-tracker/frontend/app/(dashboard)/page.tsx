import Card from '@/components/Card'
import Link from 'next/link'

export default function Page() {
  const tiles = [
    { href: '/profiles', title: 'Profiles', text: 'Browse tracked people/funds' },
    { href: '/trades', title: 'Trades', text: 'Latest disclosed trades' },
    { href: '/leaders', title: 'Leaders', text: 'Top YTD performers' },
    { href: '/alerts', title: 'Alerts', text: 'Subscribe to alerts' },
    { href: '/portfolios', title: 'Portfolios', text: 'Simulate mirror investing' },
    { href: '/watchlist', title: 'Watchlist', text: 'Your tracked profiles' },
  ]
  return (
    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
      {tiles.map(t => (
        <Card key={t.href}>
          <h3 className="text-lg font-semibold"><Link className="link" href={t.href}>{t.title}</Link></h3>
          <p className="text-sm text-neutral-400 mt-1">{t.text}</p>
        </Card>
      ))}
    </div>
  )
}
