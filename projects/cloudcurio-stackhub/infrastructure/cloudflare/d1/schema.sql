-- D1 schema for StackHub (minimal)
CREATE TABLE IF NOT EXISTS items (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  tags TEXT NOT NULL, -- comma separated
  script_bash TEXT NOT NULL,
  script_ansible TEXT NOT NULL,
  terraform TEXT,
  pulumi TEXT
);
