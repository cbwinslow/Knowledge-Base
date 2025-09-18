import '../globals.css'
import Nav from '@/components/Nav'

export const metadata = { title: 'Trades Tracker', description: 'Follow high-profile trades' }

export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Nav />
        <main className="container py-6 space-y-6">{children}</main>
      </body>
    </html>
  )
}
