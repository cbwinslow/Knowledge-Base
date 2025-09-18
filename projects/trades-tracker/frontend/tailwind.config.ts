import type { Config } from 'tailwindcss'
export default {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: { extend: { colors: { matrix: '#00FF9C' }, borderRadius: { xl2: '1.25rem' } } },
  plugins: []
} satisfies Config
