-- Minimal DDL snapshot (extend per SRS)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS social;
CREATE SCHEMA IF NOT EXISTS discuss;
CREATE SCHEMA IF NOT EXISTS methodology;
CREATE SCHEMA IF NOT EXISTS mart;

-- Core entities
CREATE TABLE IF NOT EXISTS core.person (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  party TEXT,
  jurisdiction TEXT,
  external_ids JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS core.bill (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id TEXT UNIQUE,
  title TEXT,
  jurisdiction TEXT,
  session TEXT,
  introduced_date DATE,
  status TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS core.bill_version (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bill_id UUID REFERENCES core.bill(id) ON DELETE CASCADE,
  version_no INTEGER NOT NULL,
  published_at TIMESTAMPTZ,
  text TEXT,
  embedding VECTOR(768),
  checksum TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS core.vote_event (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bill_id UUID REFERENCES core.bill(id) ON DELETE CASCADE,
  occurred_at TIMESTAMPTZ,
  result TEXT,
  roll_call JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Social
CREATE TABLE IF NOT EXISTS social_account (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_id UUID NOT NULL REFERENCES core.person(id) ON DELETE CASCADE,
  platform TEXT CHECK (platform IN ('x','twitter','facebook','instagram','youtube')),
  handle TEXT NOT NULL,
  url TEXT,
  verified BOOLEAN DEFAULT false,
  active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}'::jsonb,
  UNIQUE (platform, handle)
);

CREATE TABLE IF NOT EXISTS social_post (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id UUID REFERENCES social_account(id) ON DELETE CASCADE,
  platform_post_id TEXT,
  posted_at TIMESTAMPTZ,
  text TEXT,
  lang TEXT,
  metrics JSONB DEFAULT '{}'::jsonb,
  topics TEXT[],
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS social_reply (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES social_post(id) ON DELETE CASCADE,
  responder_handle TEXT,
  created_at TIMESTAMPTZ,
  text TEXT,
  sentiment DOUBLE PRECISION,
  toxicity DOUBLE PRECISION,
  stance TEXT
);

-- Discussion
CREATE TABLE IF NOT EXISTS discuss_comment (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_id UUID REFERENCES core.person(id),
  doc_id UUID,
  parent_id UUID REFERENCES discuss_comment(id) ON DELETE CASCADE,
  author TEXT,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  toxicity DOUBLE PRECISION,
  hidden BOOLEAN DEFAULT false
);

-- Methodology
CREATE TABLE IF NOT EXISTS methodology.metric_event (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_id UUID,
  kpi_id TEXT,
  value DOUBLE PRECISION,
  window tstzrange,
  sample_size INTEGER,
  inputs JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);
