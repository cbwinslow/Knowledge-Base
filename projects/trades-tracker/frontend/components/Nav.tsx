'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import clsx from 'clsx'
import { useEffect, useState } from 'react'
import { setToken } from '@/lib/api'

const links = [
  { href: '/profiles', label: 'Profiles' },
  { href: '/trades', label: 'Trades' },
  { href: '/leaders', label: 'Leaders' },
  { href: '/alerts', label: 'Alerts' },
  { href: '/portfolios', label: 'Portfolios' },
  { href: '/watchlist', label: 'Watchlist' },
]

export default function Nav() {
  const pathname = usePathname()
  const [logged, setLogged] = useState(false)
  useEffect(()=>{
    const t = localStorage.getItem('ttoken')
    if (t) { setToken(t); setLogged(true) }
  },[])
  return (
    <nav className="sticky top-0 z-20 backdrop-blur bg-black/30 border-b border-neutral-900">
      <div className="container py-3 flex items-center gap-6">
        <Link href="/" className="text-matrix font-semibold">TradesTracker</Link>
        <ul className="flex gap-4 text-sm">
          {links.map(l => (
            <li key={l.href}>
              <Link className={clsx('hover:underline', pathname.startsWith(l.href) && 'text-matrix')} href={l.href}>{l.label}</Link>
            </li>
          ))}
        </ul>
        <div className="ml-auto text-sm">
          {logged ? <button onClick={()=>{ localStorage.removeItem('ttoken'); setToken(null); location.href='/' }} className="link">Logout</button>
                  : <Link className="link" href="/login">Login</Link>}
        </div>
      </div>
    </nav>
  )
}
