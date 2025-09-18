-- 0001_init.sql: core tables for govdocs + basic legislative model

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS gov_domains (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  domain TEXT UNIQUE NOT NULL,
  gov_level TEXT,
  docs_count INT DEFAULT 0,
  last_crawled TIMESTAMPTZ,
  reliability_score REAL DEFAULT 0,
  coverage_score REAL DEFAULT 0,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS site_profiles (
  domain TEXT PRIMARY KEY REFERENCES gov_domains(domain) ON DELETE CASCADE,
  profile JSONB NOT NULL,
  learned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  profile_hash TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  domain TEXT NOT NULL REFERENCES gov_domains(domain),
  url TEXT NOT NULL,
  doc_type TEXT,
  title TEXT,
  published_at TIMESTAMPTZ,
  retrieved_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  content_hash TEXT NOT NULL,
  storage_uri TEXT NOT NULL,
  provenance JSONB NOT NULL,
  UNIQUE(url, content_hash)
);

CREATE TABLE IF NOT EXISTS document_text (
  doc_id UUID PRIMARY KEY REFERENCES documents(id) ON DELETE CASCADE,
  text TEXT NOT NULL
);

-- Members / Votes (minimal)
CREATE TABLE IF NOT EXISTS members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  party TEXT,
  state TEXT,
  district TEXT,
  zip TEXT,
  start_date DATE,
  end_date DATE,
  years_served INT,
  contact_email TEXT,
  twitter TEXT,
  social_media JSONB,
  UNIQUE(name, state, district, start_date)
);

CREATE TABLE IF NOT EXISTS votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  member_id UUID REFERENCES members(id),
  bill_id UUID,
  vote_cast TEXT,
  vote_date TIMESTAMPTZ,
  chamber TEXT
);

-- Vector (optional): enable manually if using pgvector
-- CREATE EXTENSION IF NOT EXISTS vector;
-- CREATE TABLE IF NOT EXISTS document_chunks (
--   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--   doc_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
--   chunk_index INT NOT NULL,
--   content TEXT NOT NULL,
--   embedding vector(1536),
--   start_char INT, end_char INT
-- );
