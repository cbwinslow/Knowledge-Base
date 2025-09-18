export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-slate-50 text-slate-900">
        <div className="max-w-5xl mx-auto p-6">
          <header className="mb-6">
            <h1 className="text-2xl font-semibold">CloudCurio Admin</h1>
          </header>
          {children}
        </div>
      </body>
    </html>
  )
}
