/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Enable static exports for Cloudflare Pages
  output: 'export',
  // Optional: Add redirects, rewrites, headers, etc.
}

module.exports = nextConfig