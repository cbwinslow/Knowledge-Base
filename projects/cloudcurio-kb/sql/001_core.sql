CREATE SCHEMA IF NOT EXISTS kb;
CREATE TABLE IF NOT EXISTS kb.users (
  user_id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE IF NOT EXISTS kb.sources (
  source_id TEXT PRIMARY KEY,
  kind TEXT NOT NULL,
  uri TEXT NOT NULL,
  fetched_at TIMESTAMPTZ,
  checksum TEXT
);
CREATE TABLE IF NOT EXISTS kb.documents (
  doc_id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  source_id TEXT REFERENCES kb.sources(source_id),
  published_at TIMESTAMPTZ,
  ingested_at TIMESTAMPTZ DEFAULT now(),
  content_type TEXT,
  language TEXT,
  cg_bill_id TEXT,
  gi_package_id TEXT
);
CREATE TABLE IF NOT EXISTS kb.entities (
  entity_id TEXT PRIMARY KEY,
  kind TEXT NOT NULL CHECK (kind IN ('Person','Organization','Committee','Bill','Legislation','Place','Topic')),
  name TEXT NOT NULL,
  aliases TEXT[] DEFAULT '{}',
  external_ids JSONB DEFAULT '{}'
);
CREATE TABLE IF NOT EXISTS kb.mentions (
  mention_id TEXT PRIMARY KEY,
  doc_id TEXT REFERENCES kb.documents(doc_id) ON DELETE CASCADE,
  entity_id TEXT REFERENCES kb.entities(entity_id) ON DELETE CASCADE,
  span_start INT,
  span_end INT,
  confidence NUMERIC
);
CREATE TABLE IF NOT EXISTS kb.relations (
  rel_id TEXT PRIMARY KEY,
  type TEXT NOT NULL CHECK (type IN ('SPONSORS','COSPONSORS','AMENDS','RELATED_TO','AFFILIATED_WITH','LOCATED_IN','CITED_BY')),
  source_id TEXT REFERENCES kb.entities(entity_id) ON DELETE CASCADE,
  target_id TEXT REFERENCES kb.entities(entity_id) ON DELETE CASCADE,
  prov_doc_id TEXT REFERENCES kb.documents(doc_id) ON DELETE SET NULL,
  prov_span_start INT,
  prov_span_end INT,
  score NUMERIC,
  commit_id TEXT
);
CREATE TABLE IF NOT EXISTS kb.threads (
  thread_id TEXT PRIMARY KEY,
  doc_id TEXT REFERENCES kb.documents(doc_id) ON DELETE CASCADE,
  created_by INT REFERENCES kb.users(user_id),
  created_at TIMESTAMPTZ DEFAULT now(),
  title TEXT
);
CREATE TABLE IF NOT EXISTS kb.comments (
  comment_id TEXT PRIMARY KEY,
  thread_id TEXT REFERENCES kb.threads(thread_id) ON DELETE CASCADE,
  parent_comment_id TEXT REFERENCES kb.comments(comment_id) ON DELETE CASCADE,
  created_by INT REFERENCES kb.users(user_id),
  created_at TIMESTAMPTZ DEFAULT now(),
  body TEXT NOT NULL,
  visibility TEXT DEFAULT 'public'
);
