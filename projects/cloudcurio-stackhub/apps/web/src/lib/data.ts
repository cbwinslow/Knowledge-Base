import seed from './seed.json'
import type { ScriptItem } from './types'

// Switchable data adapter. For D1/KV, replace with fetches to a Worker API.
export async function listItems(): Promise<ScriptItem[]> {
  return seed.items as ScriptItem[]
}
