-- ============================================================
--  SaaS Workspace Database
--  File: indexes.sql
--  Description: Indexes for all tables in schema.sql
-- ============================================================


-- ============================================================
--  TABLE: plans
-- ============================================================

-- name already has UNIQUE constraint (acts as an index)
-- Speed up filtering by price range (e.g. find affordable plans)
CREATE INDEX idx_plans_price
    ON plans (price_per_month);


-- ============================================================
--  TABLE: tenants
-- ============================================================

-- domain already has UNIQUE constraint (acts as an index)

-- All tenants on a specific plan (used in billing reports)
CREATE INDEX idx_tenants_plan
    ON tenants (plan_id);

-- Order tenants by signup date
CREATE INDEX idx_tenants_created
    ON tenants (created_at DESC);


-- ============================================================
--  TABLE: users
-- ============================================================

-- (tenant_id, email) already has UNIQUE constraint

-- All users belonging to a tenant (most common query)
CREATE INDEX idx_users_tenant
    ON users (tenant_id);

-- Filter users by role within a tenant (e.g. find all admins)
CREATE INDEX idx_users_tenant_role
    ON users (tenant_id, role);


-- ============================================================
--  TABLE: workspaces
-- ============================================================

-- All workspaces under a tenant
CREATE INDEX idx_workspaces_tenant
    ON workspaces (tenant_id);

-- Who created a workspace (audit / user profile page)
CREATE INDEX idx_workspaces_created_by
    ON workspaces (created_by);

-- Covering index for workspace list view (no table hit needed)
CREATE INDEX idx_workspaces_cover
    ON workspaces (tenant_id, id, name, created_at);


-- ============================================================
--  TABLE: deployments
-- ============================================================

-- All deployments for a tenant
CREATE INDEX idx_deployments_tenant
    ON deployments (tenant_id);

-- All deployments inside a workspace
CREATE INDEX idx_deployments_workspace
    ON deployments (workspace_id);

-- Filter deployments by status (e.g. find all 'pending' ones)
CREATE INDEX idx_deployments_status
    ON deployments (tenant_id, status);

-- Latest deployments first
CREATE INDEX idx_deployments_deployed_at
    ON deployments (deployed_at DESC);


-- ============================================================
--  TABLE: resource_usage
-- ============================================================

-- (workspace_id, usage_date) already has UNIQUE constraint

-- Billing query: sum usage for a tenant over a date range
--   Used directly inside generate_invoice procedure
CREATE INDEX idx_resource_usage_tenant_date
    ON resource_usage (tenant_id, usage_date);

-- Usage per workspace over time
CREATE INDEX idx_resource_usage_workspace_date
    ON resource_usage (workspace_id, usage_date);


-- ============================================================
--  TABLE: invoices
-- ============================================================

-- All invoices for a tenant (most common read path)
CREATE INDEX idx_invoices_tenant
    ON invoices (tenant_id, created_at DESC);

-- Duplicate period check used in generate_invoice
--   Unique constraint to enforce no double billing
CREATE UNIQUE INDEX uidx_invoices_tenant_period
    ON invoices (tenant_id, period_start, period_end);

-- Filter unpaid invoices (payment dashboard)
CREATE INDEX idx_invoices_status
    ON invoices (status, created_at DESC);

-- Covering index for invoice list view
CREATE INDEX idx_invoices_cover
    ON invoices (tenant_id, status, period_start, period_end, total_amount);


-- ============================================================
--  TABLE: audit_logs
-- ============================================================

-- All logs for a tenant (most common lookup)
CREATE INDEX idx_audit_tenant
    ON audit_logs (tenant_id, created_at DESC);

-- Filter logs by action type (e.g. find all 'generate_invoice' events)
CREATE INDEX idx_audit_action
    ON audit_logs (action, created_at DESC);

-- Filter logs by entity (e.g. all changes to 'invoices' table)
CREATE INDEX idx_audit_entity
    ON audit_logs (entity, tenant_id);

-- GIN index on JSONB details column for fast key/value search
--   e.g. WHERE details @> '{"invoice_id": 5}'
CREATE INDEX idx_audit_details_gin
    ON audit_logs USING GIN (details);


-- ============================================================
--  VERIFY — run these after applying indexes
-- ============================================================
/*
-- List all indexes on a table
SELECT indexname, indexdef
  FROM pg_indexes
 WHERE tablename = 'invoices';

-- Check if generate_invoice billing query uses the right index
EXPLAIN ANALYZE
SELECT COALESCE(SUM(api_calls), 0), COALESCE(SUM(storage_mb), 0)
  FROM resource_usage
 WHERE tenant_id  = 1
   AND usage_date >= '2025-04-01'
   AND usage_date <= '2025-04-30';

-- Should show: Index Scan using idx_resource_usage_tenant_date
*/
