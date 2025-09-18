# Profile Trades Tracker – Frontend (Next.js) & Infra (Ansible • Terraform • Pulumi)

A production‑grade Next.js UI to navigate the FastAPI backend, plus infrastructure as code to deploy and wire domains, tunnels, and services.

> Built for Cloudflare/Ubuntu homelab or small VPS. Secure defaults, idempotent playbooks, and environment‑driven config.

---

## Monorepo Layout

```
trades-tracker/
├─ backend/                       # (from previous canvas)
├─ frontend/
│  ├─ app/                        # Next.js App Router
│  │  ├─ (dashboard)/
│  │  │  ├─ layout.tsx
│  │  │  ├─ page.tsx              # Overview
│  │  │  ├─ profiles/page.tsx
│  │  │  ├─ profiles/[id]/page.tsx
│  │  │  ├─ trades/page.tsx
│  │  │  ├─ leaders/page.tsx
│  │  │  ├─ alerts/page.tsx
│  │  │  └─ portfolios/page.tsx
│  │  └─ api/edge-health/route.ts # Edge ping (optional)
│  ├─ components/
│  │  ├─ Nav.tsx
│  │  ├─ Card.tsx
│  │  ├─ Table.tsx
│  │  ├─ Badge.tsx
│  │  ├─ Toast.tsx
│  │  └─ Charts.tsx
│  ├─ lib/
│  │  ├─ api.ts                   # Typed client for FastAPI
│  │  ├─ rss.ts                   # Helpers for RSS links
│  │  └─ config.ts                # Env handling
│  ├─ public/
│  │  └─ favicon.ico
│  ├─ styles/
│  │  └─ globals.css
│  ├─ .env.example
│  ├─ next.config.ts
│  ├─ package.json
│  ├─ postcss.config.js
│  ├─ tailwind.config.ts
│  └─ Dockerfile
├─ infra/
│  ├─ ansible/
│  │  ├─ site.yml
│  │  ├─ group_vars/all.yml
│  │  ├─ roles/
│  │  │  ├─ common/tasks/main.yml
│  │  │  ├─ backend/tasks/main.yml
│  │  │  ├─ frontend/tasks/main.yml
│  │  │  └─ cloudflared/tasks/main.yml
│  │  └─ inventories/lab/hosts.ini
│  ├─ terraform/
│  │  ├─ main.tf
│  │  ├─ variables.tf
│  │  └─ outputs.tf
│  └─ pulumi/
│     ├─ Pulumi.yaml
│     ├─ Pulumi.dev.yaml
│     └─ index.ts
└─ docker-compose.yml             # optional: monorepo dev compose
```

---

## frontend/package.json

```json
{
  "name": "trades-tracker-frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.2.5",
    "react": "18.3.1",
    "react-dom": "18.3.1",
    "zod": "3.23.8",
    "ky": "1.5.0",
    "clsx": "2.1.1",
    "dayjs": "1.11.13"
  },
  "devDependencies": {
    "@types/node": "20.14.10",
    "@types/react": "18.3.3",
    "@types/react-dom": "18.3.0",
    "autoprefixer": "10.4.19",
    "postcss": "8.4.38",
    "tailwindcss": "3.4.10",
    "typescript": "5.5.4"
  }
}
```

---

## frontend/next.config.ts

```ts
import type { NextConfig } from 'next'

const config: NextConfig = {
  reactStrictMode: true,
  experimental: { serverActions: true },
}
export default config
```

---

## frontend/.env.example

```env
# URL of the FastAPI service (Docker, tunnel, or local)
NEXT_PUBLIC_API_BASE=http://localhost:8000
# Public site origin for canonical links
NEXT_PUBLIC_SITE_ORIGIN=https://cloudcurio.cc
```

---

## frontend/tailwind.config.ts

```ts
import type { Config } from 'tailwindcss'

export default {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        matrix: '#00FF9C'
      },
      borderRadius: {
        xl2: '1.25rem'
      }
    }
  },
  plugins: []
} satisfies Config
```

---

## frontend/styles/globals.css

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

:root { color-scheme: dark; }
html, body { height: 100%; }
body { @apply bg-black text-neutral-100; }

.container { @apply max-w-6xl mx-auto px-4; }
.card { @apply bg-neutral-900/60 border border-neutral-800 rounded-2xl p-4 shadow; }
.badge { @apply inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs border border-neutral-700; }
.link { @apply text-matrix hover:underline; }
.table { @apply w-full text-sm; }
.table th { @apply text-left py-2 border-b border-neutral-800; }
.table td { @apply py-2 border-b border-neutral-900; }
```

---

## frontend/lib/config.ts

```ts
export const API_BASE = process.env.NEXT_PUBLIC_API_BASE || 'http://localhost:8000'
export const SITE_ORIGIN = process.env.NEXT_PUBLIC_SITE_ORIGIN || 'http://localhost:3000'
```

---

## frontend/lib/api.ts

```ts
import ky from 'ky'
import { API_BASE } from './config'

export type Profile = { id: string; name: string; category: string; source_url?: string | null; created_at: string }
export type Trade = { id: string; profile_id: string; ticker: string; direction: 'BUY'|'SELL'; quantity: number; price: number; filed_at: string; effective_date: string; note?: string|null }

const api = ky.create({ prefixUrl: API_BASE, timeout: 20000 })

export const listProfiles = async (q?: string): Promise<Profile[]> => {
  const search = q ? `?q=${encodeURIComponent(q)}` : ''
  return api.get(`profiles${search}`).json()
}

export const getProfileTrades = async (id: string): Promise<Trade[]> => api.get(`profiles/${id}/trades`).json()

export const leadersYTD = async (top = 10): Promise<{ leaders: { profile_id: string; name: string; category: string; ytd_pct: number }[] }> => api.get(`leaders/ytd?top=${top}`).json()

export const backtest = async (profile_id: string, initial_cash = 10000) => api.post('portfolios/backtest', { json: { profile_id, initial_cash } }).json()

export const subscribe = async (email: string, profile_id?: string, rule = 'new_trade') => api.post('subscriptions', { json: { email, profile_id, rule } }).json()
```

---

## frontend/components/Nav.tsx

```tsx
'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import clsx from 'clsx'

const links = [
  { href: '/profiles', label: 'Profiles' },
  { href: '/trades', label: 'Trades' },
  { href: '/leaders', label: 'Leaders' },
  { href: '/alerts', label: 'Alerts' },
  { href: '/portfolios', label: 'Portfolios' }
]

export default function Nav() {
  const pathname = usePathname()
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
      </div>
    </nav>
  )
}
```

---

## frontend/components/Card.tsx

```tsx
import { ReactNode } from 'react'
export default function Card({ children, className = '' }: { children: ReactNode, className?: string }) {
  return <div className={`card ${className}`}>{children}</div>
}
```

---

## frontend/components/Table.tsx

```tsx
import { ReactNode } from 'react'
export function T({ children }: { children: ReactNode }) { return <table className="table">{children}</table> }
export function TH({ children }: { children: ReactNode }) { return <th>{children}</th> }
export function TR({ children }: { children: ReactNode }) { return <tr>{children}</tr> }
export function TD({ children }: { children: ReactNode }) { return <td>{children}</td> }
```

---

## frontend/components/Badge.tsx

```tsx
export default function Badge({ children }: { children: string }) {
  return <span className="badge">{children}</span>
}
```

---

## frontend/components/Toast.tsx

```tsx
'use client'
import { useEffect, useState } from 'react'

export default function Toast({ message }: { message: string }) {
  const [show, setShow] = useState(true)
  useEffect(() => {
    const t = setTimeout(() => setShow(false), 3000)
    return () => clearTimeout(t)
  }, [])
  if (!show) return null
  return <div className="fixed bottom-4 right-4 bg-neutral-900 border border-neutral-700 rounded-xl px-4 py-2">{message}</div>
}
```

---

## frontend/components/Charts.tsx (placeholder)

```tsx
'use client'
import { useEffect, useRef } from 'react'

// Simple canvas chart placeholder – swap for Recharts later
export default function LineChart({ points }: { points: number[] }) {
  const ref = useRef<HTMLCanvasElement | null>(null)
  useEffect(() => {
    const c = ref.current; if (!c) return
    const ctx = c.getContext('2d'); if (!ctx) return
    ctx.clearRect(0,0,c.width,c.height)
    const w = c.width, h = c.height
    const max = Math.max(...points), min = Math.min(...points)
    const norm = (v:number)=> (h - ((v - min) / (max - min || 1)) * h)
    ctx.beginPath()
    points.forEach((v,i)=>{
      const x = (i/(points.length-1||1))*w
      const y = norm(v)
      if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y)
    })
    ctx.strokeStyle = '#00FF9C'
    ctx.lineWidth = 2
    ctx.stroke()
  }, [points])
  return <canvas ref={ref} width={600} height={160} className="w-full" />
}
```

---

## frontend/app/(dashboard)/layout.tsx

```tsx
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
```

---

## frontend/app/(dashboard)/page.tsx (Overview)

```tsx
import Card from '@/components/Card'
import Link from 'next/link'

export default function Page() {
  const tiles = [
    { href: '/profiles', title: 'Profiles', text: 'Browse tracked people/funds' },
    { href: '/trades', title: 'Trades', text: 'Latest disclosed trades' },
    { href: '/leaders', title: 'Leaders', text: 'Top YTD performers' },
    { href: '/alerts', title: 'Alerts', text: 'Subscribe to new-trade alerts' },
    { href: '/portfolios', title: 'Portfolios', text: 'Simulate mirror investing' }
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
```

---

## frontend/app/(dashboard)/profiles/page.tsx

```tsx
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
```

---

## frontend/app/(dashboard)/profiles/[id]/page.tsx

```tsx
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
          <thead>
            <TR>
              <TH>Ticker</TH><TH>Dir</TH><TH>Qty</TH><TH>Price</TH><TH>Filed</TH><TH>Effective</TH>
            </TR>
          </thead>
          <tbody>
            {trades.map(t => (
              <TR key={t.id}>
                <TD>{t.ticker}</TD>
                <TD>{t.direction}</TD>
                <TD>{t.quantity}</TD>
                <TD>${t.price.toFixed(2)}</TD>
                <TD>{new Date(t.filed_at).toLocaleString()}</TD>
                <TD>{t.effective_date}</TD>
              </TR>
            ))}
          </tbody>
        </T>
      </Card>
    </div>
  )
}
```

---

## frontend/app/(dashboard)/trades/page.tsx

```tsx
import { listProfiles, getProfileTrades } from '@/lib/api'
import Card from '@/components/Card'
import { T, TH, TR, TD } from '@/components/Table'

export const dynamic = 'force-dynamic'

export default async function Page() {
  const profiles = await listProfiles()
  const byProfile = await Promise.all(profiles.map(async p => ({ p, trades: await getProfileTrades(p.id) })))
  return (
    <div className="space-y-6">
      <h1 className="text-xl font-semibold">Latest Trades (by Profile)</h1>
      {byProfile.map(({p, trades}) => (
        <Card key={p.id}>
          <h3 className="font-semibold text-matrix">{p.name}</h3>
          <T>
            <thead>
              <TR><TH>Ticker</TH><TH>Dir</TH><TH>Qty</TH><TH>Price</TH><TH>Filed</TH></TR>
            </thead>
            <tbody>
              {trades.slice(0, 8).map(t => (
                <TR key={t.id}><TD>{t.ticker}</TD><TD>{t.direction}</TD><TD>{t.quantity}</TD><TD>${t.price.toFixed(2)}</TD><TD>{new Date(t.filed_at).toLocaleString()}</TD></TR>
              ))}
            </tbody>
          </T>
        </Card>
      ))}
    </div>
  )
}
```

---

## frontend/app/(dashboard)/leaders/page.tsx

```tsx
import { leadersYTD } from '@/lib/api'
import Card from '@/components/Card'

export const dynamic = 'force-dynamic'

export default async function Page() {
  const { leaders } = await leadersYTD(20)
  return (
    <div className="space-y-4">
      <h1 className="text-xl font-semibold">Top Performers (YTD)</h1>
      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
        {leaders.map(l => (
          <Card key={l.profile_id}>
            <div className="flex items-center justify-between">
              <div>
                <div className="text-matrix font-semibold">{l.name}</div>
                <div className="text-xs text-neutral-400">{l.category}</div>
              </div>
              <div className="text-lg font-semibold">{l.ytd_pct.toFixed(2)}%</div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  )
}
```

---

## frontend/app/(dashboard)/alerts/page.tsx

```tsx
'use client'
import { useState } from 'react'
import { listProfiles, subscribe } from '@/lib/api'
import useSWR from 'swr'

const fetcher = (key: string) => fetch(key).then(r => r.json())

export default function Page() {
  const [email, setEmail] = useState('')
  const [ok, setOk] = useState<string | null>(null)
  const { data } = useSWR('/api/_profiles', async () => await listProfiles())

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    const profile_id = (document.getElementById('profile') as HTMLSelectElement)?.value || undefined
    const res = await subscribe(email, profile_id)
    setOk(`Subscribed: ${res.subscription_id}`)
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-semibold">Alerts</h1>
      <form onSubmit={onSubmit} className="card flex flex-col gap-3 max-w-md">
        <input value={email} onChange={e=>setEmail(e.target.value)} required placeholder="Email" className="bg-black border border-neutral-800 rounded-xl px-3 py-2" />
        <select id="profile" className="bg-black border border-neutral-800 rounded-xl px-3 py-2">
          <option value="">Any profile</option>
          {(data||[]).map((p:any)=> <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
        <button className="bg-matrix/20 border border-matrix/40 rounded-xl px-3 py-2 hover:bg-matrix/30" type="submit">Subscribe</button>
        {ok && <div className="text-xs text-neutral-400">{ok}</div>}
      </form>
    </div>
  )
}
```

---

## frontend/app/(dashboard)/portfolios/page.tsx

```tsx
'use client'
import { useEffect, useState } from 'react'
import { listProfiles, backtest } from '@/lib/api'
import LineChart from '@/components/Charts'

export default function Page() {
  const [profiles, setProfiles] = useState<any[]>([])
  const [selected, setSelected] = useState<string>('')
  const [result, setResult] = useState<any | null>(null)

  useEffect(()=>{ (async()=> setProfiles(await listProfiles()))() },[])

  const run = async () => {
    if(!selected) return
    const res = await backtest(selected, 10000)
    setResult(res)
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-semibold">Paper Portfolio</h1>
      <div className="card flex gap-2 max-w-xl">
        <select className="bg-black border border-neutral-800 rounded-xl px-3 py-2 flex-1" value={selected} onChange={e=>setSelected(e.target.value)}>
          <option value="">Select profile…</option>
          {profiles.map((p:any)=> <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
        <button className="bg-matrix/20 border border-matrix/40 rounded-xl px-3 py-2 hover:bg-matrix/30" onClick={run}>Run</button>
      </div>
      {result && (
        <div className="grid md:grid-cols-2 gap-4">
          <div className="card">
            <div className="text-sm text-neutral-400">Value</div>
            <div className="text-2xl font-semibold">${result.portfolio_value.toLocaleString()}</div>
            <div className="text-xs">Cash: ${result.cash.toLocaleString()} | P&L: {result.pnl_percent}%</div>
          </div>
          <div className="card">
            <div className="text-sm text-neutral-400 mb-2">Positions</div>
            <ul className="text-sm list-disc ml-5">
              {Object.entries(result.positions).map(([k,v])=> <li key={k}>{k}: {Number(v).toFixed(4)}</li>)}
            </ul>
          </div>
          <div className="md:col-span-2 card">
            <div className="text-sm text-neutral-400 mb-2">Equity Curve (placeholder)</div>
            <LineChart points={[100,101,99,103,102,106,108,107,112]} />
          </div>
        </div>
      )}
    </div>
  )
}
```

---

## frontend/Dockerfile

```dockerfile
# syntax=docker/dockerfile:1
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* .npmrc* ./
RUN npm ci || npm install

FROM node:20-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-alpine AS run
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/.next ./.next
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/node_modules ./node_modules
EXPOSE 3000
CMD ["npm","start"]
```

---

## docker-compose.yml (monorepo dev)

```yaml
version: '3.9'
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: tracker
      POSTGRES_USER: tracker
      POSTGRES_PASSWORD: tracker
    volumes: [pgdata:/var/lib/postgresql/data]

  api:
    build: ./backend
    environment:
      - DB_URL=postgresql+psycopg2://tracker:tracker@db:5432/tracker
      - CORS_ORIGINS=http://localhost:3000
    depends_on: [db]
    ports: ["8000:8000"]

  web:
    build: ./frontend
    environment:
      - NEXT_PUBLIC_API_BASE=http://api:8000
    depends_on: [api]
    ports: ["3000:3000"]

volumes:
  pgdata:
```

---

# Infrastructure as Code

## Ansible – infra/ansible/site.yml

```yaml
---
# Site playbook – idempotent setup for docker, docker-compose app, and cloudflared tunnel.
- hosts: app_hosts
  become: true
  vars_files:
    - group_vars/all.yml
  tasks:
    - name: Ensure apt packages
      ansible.builtin.package:
        name: [curl, ca-certificates, gnupg, lsb-release]
        state: present

    - name: Install Docker (official repo)
      ansible.builtin.shell: |
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(. /etc/os-release; echo "$VERSION_CODENAME") stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update -y
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      args: { creates: /usr/bin/docker }

    - name: Create app directory
      ansible.builtin.file:
        path: "{{ app_dir }}"
        state: directory
        mode: '0755'

    - name: Sync monorepo (rsync)
      ansible.posix.synchronize:
        src: "{{ local_repo_path }}/"
        dest: "{{ app_dir }}/"
        delete: false
        archive: true

    - name: Compose up
      community.docker.docker_compose_v2:
        project_src: "{{ app_dir }}"
        state: present

    - name: Install cloudflared
      ansible.builtin.shell: |
        if ! command -v cloudflared >/dev/null; then
          curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o /tmp/cf.deb
          dpkg -i /tmp/cf.deb
        fi
      args: { executable: /bin/bash }

    - name: Configure cloudflared tunnel service
      ansible.builtin.copy:
        dest: /etc/cloudflared/config.yml
        content: |
          tunnel: {{ cloudflare_tunnel_id }}
          credentials-file: /etc/cloudflared/{{ cloudflare_tunnel_id }}.json
          ingress:
            - hostname: {{ api_host }}
              service: http://localhost:8000
            - hostname: {{ web_host }}
              service: http://localhost:3000
            - service: http_status:404
      notify: [restart cloudflared]

  handlers:
    - name: restart cloudflared
      ansible.builtin.service:
        name: cloudflared
        state: restarted
```

### Ansible group_vars/all.yml

```yaml
app_dir: /opt/trades-tracker
local_repo_path: /home/{{ ansible_user }}/trades-tracker
api_host: api.cloudcurio.cc
web_host: app.cloudcurio.cc
cloudflare_tunnel_id: "<your-tunnel-id>"
```

### Ansible inventories/lab/hosts.ini

```ini
[app_hosts]
cbwdellr720 ansible_host=192.168.4.10 ansible_user=cbwinslow
```

---

## Terraform – infra/terraform/main.tf (Cloudflare DNS + Tunnel routes)

```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    cloudflare = { source = "cloudflare/cloudflare", version = ">= 4.30.0" }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Zone
data "cloudflare_zones" "zone" { name = var.zone_name }
locals { zone_id = data.cloudflare_zones.zone.zones[0].id }

# DNS records for API & Web – proxied through Cloudflare (CNAME to tunnel)
resource "cloudflare_record" "api" {
  zone_id = local.zone_id
  name    = var.api_subdomain
  value   = var.tunnel_cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "web" {
  zone_id = local.zone_id
  name    = var.web_subdomain
  value   = var.tunnel_cname
  type    = "CNAME"
  proxied = true
}
```

### infra/terraform/variables.tf

```hcl
variable "cloudflare_api_token" { type = string }
variable "zone_name" { type = string  default = "cloudcurio.cc" }
variable "api_subdomain" { type = string default = "api" }
variable "web_subdomain" { type = string default = "app" }
# The tunnel CNAME target looks like: <TUNNEL_ID>.cfargotunnel.com
variable "tunnel_cname" { type = string }
```

### infra/terraform/outputs.tf

```hcl
output "api_fqdn" { value = "${var.api_subdomain}.${var.zone_name}" }
output "web_fqdn" { value = "${var.web_subdomain}.${var.zone_name}" }
```

---

## Pulumi – infra/pulumi/index.ts (Cloudflare alt)

```ts
import * as cloudflare from '@pulumi/cloudflare'
import * as pulumi from '@pulumi/pulumi'

const config = new pulumi.Config()
const zoneName = config.get('zoneName') || 'cloudcurio.cc'
const apiSub = config.get('apiSub') || 'api'
const webSub = config.get('webSub') || 'app'
const tunnelCname = config.require('tunnelCname')

const zone = cloudflare.getZonesOutput({ filter: { name: zoneName } })
const zoneId = zone.zones[0].id

new cloudflare.Record('api', {
  zoneId,
  name: apiSub,
  type: 'CNAME',
  value: tunnelCname,
  proxied: true,
})

new cloudflare.Record('web', {
  zoneId,
  name: webSub,
  type: 'CNAME',
  value: tunnelCname,
  proxied: true,
})
```

### Pulumi.yaml

```yaml
name: trades-tracker-infra
runtime: nodejs
description: Cloudflare DNS for Trades Tracker
```

### Pulumi.dev.yaml

```yaml
config:
  trades-tracker-infra:zoneName: cloudcurio.cc
  trades-tracker-infra:apiSub: api
  trades-tracker-infra:webSub: app
  trades-tracker-infra:tunnelCname: "<TUNNEL_ID>.cfargotunnel.com"
```

---

## Security & Deployment Notes

- Put Cloudflare API tokens in your secret store (Bitwarden CLI) and feed to Terraform/Pulumi via environment or encrypted state.
- Cloudflared credentials JSON must be installed on the host; Ansible playbook assumes it already exists at `/etc/cloudflared/<tunnel>.json`.
- For HTTPS end‑to‑end, terminate at Cloudflare and optionally enable mTLS to origin.

---

## How to run (dev)

```bash
# Monorepo root
docker compose up -d --build
# Seed demo data
curl -X POST http://localhost:8000/_admin/seed
# Open http://localhost:3000
```

## How to deploy (Ansible + Cloudflare)

```bash
# 1) Provision DNS via Terraform or Pulumi (choose one)
cd infra/terraform && terraform init && terraform apply \
  -var="cloudflare_api_token=$CLOUDFLARE_TOKEN" \
  -var="tunnel_cname=$TUNNEL_ID.cfargotunnel.com"

# 2) Push code to server and compose up via Ansible
cd ../ansible
ansible-playbook -i inventories/lab/hosts.ini site.yml
```

---

## Immediate Next Improvements

1. **Auth + Watchlists**: Add NextAuth + JWT talking to the backend, per‑user watchlists/alerts.
2. **Charts & Series**: Replace placeholder chart with Recharts and add a `/series` API for equity curves.
3. **Edge RSS Cache**: Cloudflare Worker to cache `/rss/profile/:id` and serve at `rss.cloudcurio.cc`.

