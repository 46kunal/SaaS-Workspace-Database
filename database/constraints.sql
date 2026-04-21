-- PART 1: constraints.sql
-- Updated to match actual schema.sql structure

-- 1. NOT NULL constraints on important columns
ALTER TABLE tenants 
    ALTER COLUMN name SET NOT NULL,
    ALTER COLUMN created_at SET NOT NULL;

ALTER TABLE users 
    ALTER COLUMN tenant_id SET NOT NULL,
    ALTER COLUMN email SET NOT NULL,
    ALTER COLUMN full_name SET NOT NULL,
    ALTER COLUMN created_at SET NOT NULL;

ALTER TABLE workspaces 
    ALTER COLUMN tenant_id SET NOT NULL,
    ALTER COLUMN name SET NOT NULL,
    ALTER COLUMN created_at SET NOT NULL;

ALTER TABLE deployments 
    ALTER COLUMN tenant_id SET NOT NULL,
    ALTER COLUMN workspace_id SET NOT NULL,
    ALTER COLUMN name SET NOT NULL,
    ALTER COLUMN version SET NOT NULL,
    ALTER COLUMN status SET NOT NULL,
    ALTER COLUMN deployed_at SET NOT NULL;

ALTER TABLE resource_usage 
    ALTER COLUMN tenant_id SET NOT NULL,
    ALTER COLUMN workspace_id SET NOT NULL,
    ALTER COLUMN api_calls SET NOT NULL,
    ALTER COLUMN storage_mb SET NOT NULL,
    ALTER COLUMN usage_date SET NOT NULL,
    ALTER COLUMN recorded_at SET NOT NULL;

ALTER TABLE invoices 
    ALTER COLUMN tenant_id SET NOT NULL,
    ALTER COLUMN total_amount SET NOT NULL,
    ALTER COLUMN status SET NOT NULL,
    ALTER COLUMN created_at SET NOT NULL;

ALTER TABLE audit_logs 
    ALTER COLUMN tenant_id SET NOT NULL,
    ALTER COLUMN action SET NOT NULL,
    ALTER COLUMN entity SET NOT NULL,
    ALTER COLUMN created_at SET NOT NULL;

-- 2. UNIQUE constraints: users.email should be unique per tenant
ALTER TABLE users ADD CONSTRAINT unique_tenant_email UNIQUE (tenant_id, email);

-- 3. CHECK constraints
ALTER TABLE resource_usage ADD CONSTRAINT check_api_calls_positive CHECK (api_calls >= 0);
ALTER TABLE resource_usage ADD CONSTRAINT check_storage_mb_positive CHECK (storage_mb >= 0);
ALTER TABLE invoices ADD CONSTRAINT check_total_amount_positive CHECK (total_amount >= 0);

-- 4. UNIQUE constraint on resource_usage (one record per workspace per day)
ALTER TABLE resource_usage ADD CONSTRAINT unique_workspace_date UNIQUE (workspace_id, usage_date);
