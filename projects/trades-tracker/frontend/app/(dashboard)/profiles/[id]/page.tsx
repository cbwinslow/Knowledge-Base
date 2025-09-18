import { getProfileTrades } from '@/lib/api'
import { API_BASE } from '@/lib/config'
import Card from '@/components/Card'
import { T, TH, TR, TD } from '@/components/Table'
export const dynamic = 'force-dynamic'
export default async function Page({ params }: { params: { id: string } }) {
  const trades = await getProfileTrades(params.id)
  const rss = `${API_BASE}/rss/profile/${params.id}`
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold">Profile Trades</h1>
        <a className="link" href={rss} target="_blank">RSS Feed</a>
      </div>
      <Card>
        <T>
          <thead><TR><TH>Ticker</TH><TH>Dir</TH><TH>Qty</TH><TH>Price</TH><TH>Filed</TH><TH>Effective</TH></TR></thead>
          <tbody>
            {trades.map(t => (
              <TR key={t.id}><TD>{t.ticker}</TD><TD>{t.direction}</TD><TD>{t.quantity}</TD><TD>${t.price.toFixed(2)}</TD><TD>{new Date(t.filed_at).toLocaleString()}</TD><TD>{t.effective_date}</TD></TR>
            ))}
          </tbody>
        </T>
      </Card>
    </div>
  )
}
