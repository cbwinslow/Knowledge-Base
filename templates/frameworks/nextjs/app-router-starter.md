# Next.js App Router Starter Template

## Overview
Modern Next.js 14+ starter template using App Router, TypeScript, Tailwind CSS, and best practices.

## Project Structure

```
nextjs-app/
├── app/
│   ├── (auth)/
│   │   ├── login/
│   │   │   └── page.tsx
│   │   └── register/
│   │       └── page.tsx
│   ├── (dashboard)/
│   │   ├── dashboard/
│   │   │   ├── page.tsx
│   │   │   └── loading.tsx
│   │   └── layout.tsx
│   ├── api/
│   │   ├── auth/
│   │   │   └── [...nextauth]/
│   │   │       └── route.ts
│   │   └── users/
│   │       └── route.ts
│   ├── layout.tsx
│   ├── page.tsx
│   ├── loading.tsx
│   ├── error.tsx
│   └── not-found.tsx
├── components/
│   ├── ui/
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   └── input.tsx
│   ├── layout/
│   │   ├── header.tsx
│   │   ├── footer.tsx
│   │   └── sidebar.tsx
│   └── providers/
│       └── theme-provider.tsx
├── lib/
│   ├── utils.ts
│   ├── api.ts
│   └── db.ts
├── types/
│   └── index.ts
├── public/
├── .env.local
├── .env.example
├── next.config.js
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

## Configuration Files

### package.json
```json
{
  "name": "nextjs-app-starter",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "next": "14.0.0",
    "react": "^18",
    "react-dom": "^18",
    "typescript": "^5"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "autoprefixer": "^10",
    "eslint": "^8",
    "eslint-config-next": "14.0.0",
    "postcss": "^8",
    "tailwindcss": "^3",
    "typescript": "^5"
  }
}
```

### next.config.js
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    domains: ['example.com'],
    formats: ['image/avif', 'image/webp'],
  },
  experimental: {
    serverActions: true,
  },
}

module.exports = nextConfig
```

### tailwind.config.ts
```typescript
import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        border: "hsl(var(--border))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
      },
    },
  },
  plugins: [],
}

export default config
```

### .env.example
```env
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/db"

# Authentication
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="your-secret-key"

# API Keys
API_KEY="your-api-key"
```

## Core Files

### app/layout.tsx
```typescript
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Next.js App',
  description: 'Modern Next.js application',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  )
}
```

### app/page.tsx
```typescript
import Link from 'next/link'

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <h1 className="text-4xl font-bold mb-8">Welcome to Next.js</h1>
      <div className="flex gap-4">
        <Link 
          href="/dashboard"
          className="px-6 py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
        >
          Go to Dashboard
        </Link>
      </div>
    </main>
  )
}
```

### app/api/users/route.ts
```typescript
import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  try {
    // Fetch users from database
    const users = await fetchUsers()
    
    return NextResponse.json(users)
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch users' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    
    // Validate and create user
    const user = await createUser(body)
    
    return NextResponse.json(user, { status: 201 })
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to create user' },
      { status: 500 }
    )
  }
}
```

### lib/utils.ts
```typescript
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(date)
}

export async function fetcher<T>(url: string): Promise<T> {
  const res = await fetch(url)
  
  if (!res.ok) {
    throw new Error('Failed to fetch data')
  }
  
  return res.json()
}
```

### types/index.ts
```typescript
export interface User {
  id: string
  name: string
  email: string
  image?: string
  createdAt: Date
  updatedAt: Date
}

export interface Post {
  id: string
  title: string
  content: string
  published: boolean
  authorId: string
  author?: User
  createdAt: Date
  updatedAt: Date
}

export interface ApiResponse<T> {
  data: T
  error?: string
  meta?: {
    page: number
    limit: number
    total: number
  }
}
```

## Server Actions

### app/actions.ts
```typescript
'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

export async function createPost(formData: FormData) {
  const title = formData.get('title') as string
  const content = formData.get('content') as string
  
  try {
    // Create post in database
    const post = await db.post.create({
      data: { title, content }
    })
    
    revalidatePath('/posts')
    redirect(`/posts/${post.id}`)
  } catch (error) {
    return { error: 'Failed to create post' }
  }
}

export async function deletePost(id: string) {
  try {
    await db.post.delete({ where: { id } })
    revalidatePath('/posts')
  } catch (error) {
    return { error: 'Failed to delete post' }
  }
}
```

## Usage

### 1. Create Project
```bash
npx create-next-app@latest my-app --typescript --tailwind --app
cd my-app
```

### 2. Copy Template Files
Copy the files from this template into your project

### 3. Install Dependencies
```bash
npm install
```

### 4. Configure Environment
```bash
cp .env.example .env.local
# Edit .env.local with your values
```

### 5. Run Development Server
```bash
npm run dev
```

## Features Included

- ✅ TypeScript configuration
- ✅ Tailwind CSS setup
- ✅ App Router with nested layouts
- ✅ API routes
- ✅ Server Actions
- ✅ Loading and error states
- ✅ Metadata API
- ✅ Image optimization
- ✅ Environment variables
- ✅ Utility functions
- ✅ Type definitions

## Best Practices

1. **Server Components**: Use Server Components by default
2. **Client Components**: Only use 'use client' when needed
3. **Data Fetching**: Fetch data in Server Components
4. **Caching**: Leverage Next.js caching strategies
5. **Images**: Always use next/image
6. **Metadata**: Use Metadata API for SEO
7. **Error Handling**: Implement error.tsx files
8. **Loading States**: Add loading.tsx files

## Common Patterns

### Data Fetching
```typescript
// Server Component
async function getData() {
  const res = await fetch('https://api.example.com/data', {
    next: { revalidate: 3600 } // Cache for 1 hour
  })
  
  if (!res.ok) throw new Error('Failed to fetch')
  
  return res.json()
}

export default async function Page() {
  const data = await getData()
  
  return <div>{/* Render data */}</div>
}
```

### Client Component
```typescript
'use client'

import { useState } from 'react'

export default function Counter() {
  const [count, setCount] = useState(0)
  
  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  )
}
```

## Deployment

### Vercel (Recommended)
```bash
npm install -g vercel
vercel
```

### Docker
```dockerfile
FROM node:18-alpine AS base
# ... (see full Dockerfile in docker templates)
```

## Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [App Router Guide](https://nextjs.org/docs/app)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [TypeScript](https://www.typescriptlang.org/docs)

---

**Version**: 1.0 (Next.js 14+)  
**Last Updated**: 2025-11-01
