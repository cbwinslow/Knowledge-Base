import type { Bundle } from './types'
export const bundles: Bundle[] = [
  { id:'harden-basic', name:'Harden: Basic Server', description:'Fail2ban + Docker core + Cloudflare Tunnel', itemIds:['fail2ban','docker-core','cf-tunnel'] },
  { id:'llm-stack', name:'AI: Local LLM Stack (GPU)', description:'Docker core + NVIDIA toolkit + OpenSearch (for logs)', itemIds:['docker-core','nvidia-ctk','opensearch'] },
]
