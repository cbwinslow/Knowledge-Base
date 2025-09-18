# Cloudflare Wiring (cloudcurio.cc)

## Build & Deploy
```bash
npm install
npm run build
npx wrangler d1 create stackhub_db
npx wrangler d1 execute stackhub_db --file d1/schema.sql
npm run deploy
```
