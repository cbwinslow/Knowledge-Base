import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'CloudCurio StackHub',
  description: 'Curate and export scripts, configs, and stacks — in one place.',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
