-- Twlv20 AI OS Phase 1 tenant schema + RLS baseline
-- Drafted from ClickUp task 86b9m4z5v and architecture docs.
-- Apply to database: twlv20

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS tenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9][a-z0-9-]*$'),
  name text NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO tenants (slug, name) VALUES
  ('pure-peptide', 'Pure Peptide Solutions'),
  ('agere-sciences', 'AgereSciences'),
  ('sru', 'Sales Recruiting University'),
  ('twlv20-internal', 'Twlv20 Internal')
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  updated_at = now();

CREATE OR REPLACE FUNCTION app_current_tenant_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT NULLIF(current_setting('app.tenant_id', true), '')::uuid;
$$;

CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS runs (
  run_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  workflow text NOT NULL,
  agent text NOT NULL,
  timestamp timestamptz NOT NULL DEFAULT now(),
  trigger_source text NOT NULL,
  input_hash text,
  confidence_score numeric CHECK (confidence_score IS NULL OR (confidence_score >= 0 AND confidence_score <= 1)),
  hil_status text NOT NULL DEFAULT 'pending' CHECK (hil_status IN ('pending', 'approved', 'rejected', 'auto')),
  outcome text,
  token_cost numeric(12,6) NOT NULL DEFAULT 0 CHECK (token_cost >= 0),
  api_cost numeric(12,6) NOT NULL DEFAULT 0 CHECK (api_cost >= 0),
  duration_ms integer CHECK (duration_ms IS NULL OR duration_ms >= 0),
  artifact_refs jsonb NOT NULL DEFAULT '[]'::jsonb,
  error_payload jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS artifacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  run_id uuid REFERENCES runs(run_id) ON DELETE SET NULL,
  kind text NOT NULL,
  uri text NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  run_id uuid REFERENCES runs(run_id) ON DELETE SET NULL,
  requested_by text,
  approver text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
  request_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  decision_payload jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  decided_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tenant_secrets_refs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  provider text NOT NULL DEFAULT 'infisical',
  secret_path text NOT NULL,
  purpose text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, provider, secret_path)
);

CREATE INDEX IF NOT EXISTS idx_runs_tenant_timestamp ON runs (tenant_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_runs_workflow ON runs (workflow);
CREATE INDEX IF NOT EXISTS idx_artifacts_tenant_run ON artifacts (tenant_id, run_id);
CREATE INDEX IF NOT EXISTS idx_approvals_tenant_status ON approvals (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_secret_refs_tenant ON tenant_secrets_refs (tenant_id);

DROP TRIGGER IF EXISTS trg_tenants_touch_updated_at ON tenants;
CREATE TRIGGER trg_tenants_touch_updated_at
BEFORE UPDATE ON tenants
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS trg_runs_touch_updated_at ON runs;
CREATE TRIGGER trg_runs_touch_updated_at
BEFORE UPDATE ON runs
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS trg_artifacts_touch_updated_at ON artifacts;
CREATE TRIGGER trg_artifacts_touch_updated_at
BEFORE UPDATE ON artifacts
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS trg_approvals_touch_updated_at ON approvals;
CREATE TRIGGER trg_approvals_touch_updated_at
BEFORE UPDATE ON approvals
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS trg_secret_refs_touch_updated_at ON tenant_secrets_refs;
CREATE TRIGGER trg_secret_refs_touch_updated_at
BEFORE UPDATE ON tenant_secrets_refs
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

ALTER TABLE runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE artifacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_secrets_refs ENABLE ROW LEVEL SECURITY;

ALTER TABLE runs FORCE ROW LEVEL SECURITY;
ALTER TABLE artifacts FORCE ROW LEVEL SECURITY;
ALTER TABLE approvals FORCE ROW LEVEL SECURITY;
ALTER TABLE tenant_secrets_refs FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_runs ON runs;
CREATE POLICY tenant_isolation_runs ON runs
  USING (tenant_id = app_current_tenant_id())
  WITH CHECK (tenant_id = app_current_tenant_id());

DROP POLICY IF EXISTS tenant_isolation_artifacts ON artifacts;
CREATE POLICY tenant_isolation_artifacts ON artifacts
  USING (tenant_id = app_current_tenant_id())
  WITH CHECK (tenant_id = app_current_tenant_id());

DROP POLICY IF EXISTS tenant_isolation_approvals ON approvals;
CREATE POLICY tenant_isolation_approvals ON approvals
  USING (tenant_id = app_current_tenant_id())
  WITH CHECK (tenant_id = app_current_tenant_id());

DROP POLICY IF EXISTS tenant_isolation_secret_refs ON tenant_secrets_refs;
CREATE POLICY tenant_isolation_secret_refs ON tenant_secrets_refs
  USING (tenant_id = app_current_tenant_id())
  WITH CHECK (tenant_id = app_current_tenant_id());

GRANT USAGE ON SCHEMA public TO twlv20_app;
GRANT SELECT ON tenants TO twlv20_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON runs, artifacts, approvals, tenant_secrets_refs TO twlv20_app;

COMMIT;
