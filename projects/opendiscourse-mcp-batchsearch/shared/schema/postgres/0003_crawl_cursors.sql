-- 0003_crawl_cursors.sql: track per-domain crawl cursors and seen URLs
CREATE TABLE IF NOT EXISTS crawl_cursors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  domain TEXT NOT NULL REFERENCES gov_domains(domain) ON DELETE CASCADE,
  last_run TIMESTAMPTZ DEFAULT now(),
  pos INT DEFAULT 0,
  total INT DEFAULT 0,
  url_list JSONB NOT NULL DEFAULT '[]',
  UNIQUE(domain)
);
