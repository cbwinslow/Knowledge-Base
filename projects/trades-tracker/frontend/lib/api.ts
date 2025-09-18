import ky from 'ky'
import { API_BASE } from './config'

export type Profile = { id: string; name: string; category: string; source_url?: string | null; created_at: string }
export type Trade = { id: string; profile_id: string; ticker: string; direction: 'BUY'|'SELL'; quantity: number; price: number; filed_at: string; effective_date: string; note?: string|null }

let token: string | null = null
export const setToken = (t: string | null) => { token = t }

const api = ky.create({ prefixUrl: API_BASE, timeout: 20000, hooks: { beforeRequest: [req => { if (token) req.headers.set('Authorization', `Bearer ${token}`) }] } })

export const listProfiles = async (q?: string): Promise<Profile[]> => {
  const search = q ? `?q=${encodeURIComponent(q)}` : ''
  return api.get(`profiles${search}`).json()
}
export const getProfileTrades = async (id: string): Promise<Trade[]> => api.get(`profiles/${id}/trades`).json()
export const leadersYTD = async (top = 10): Promise<{ leaders: { profile_id: string; name: string; category: string; ytd_pct: number }[] }> => api.get(`leaders/ytd?top=${top}`).json()
export const backtest = async (profile_id: string, initial_cash = 10000) => api.post('portfolios/backtest', { json: { profile_id, initial_cash } }).json()
export const backtestSeries = async (profile_id: string, initial_cash = 10000) => api.post('portfolios/backtest_series', { json: { profile_id, initial_cash } }).json()
export const subscribe = async (email: string, profile_id?: string, rule = 'new_trade') => api.post('subscriptions', { json: { email, profile_id, rule } }).json()

export const register = async (email: string, password: string) => api.post('auth/register', { json: { email, password } }).json()
export const login = async (email: string, password: string) => api.post('auth/login', { json: { email, password } }).json()

export const listWatchlist = async () => api.get('watchlist').json()
export const addWatch = async (profile_id: string) => api.post('watchlist', { json: { profile_id } }).json()
