-- PART 1: constraints.sql

-- 1. NOT NULL constraints on important columns
ALTER TABLE tenants 
    ALTER COLUMN name SET NOT NULL,
    ALTER COLUMN email SET NOT NULL,
    ALTER COLUMN created_at SET NOT NULL;

ALTER TABLE users 
    ALTER COLUMN tenant_id SET NOT NULL,
    ALTER COLUMN name SET NOT NULL,
    ALTER COLUMN email SET NOT NULL,
    ALTER COLUMN created_at SET NOT NULL,
    ALTER COLUMN updated_at SET NOT NULL;

ALTER TABLE workspaces 
    ALTER COLUMN tenant_id SET NOT NULL,
    ALTER COLUMN name SET NOT NULL,
    ALTER COLUMN created_at SET NOT NULL;

ALTER TABLE applications 
    ALTER COLUMN workspace_id SET NOT NULL,
    ALTER COLUMN tenant_id SET NOT NULL,
    ALTER COLUMN name SET NOT NULL,
    ALTER COLUMN created_at SET NOT NULL;

ALTER TABLE usage_logs 
    ALTER COLUMN tenant_id SET NOT NULL,
    ALTER COLUMN app_id SET NOT NULL,
    ALTER COLUMN usage_count SET NOT NULL,
    ALTER COLUMN created_at SET NOT NULL;

ALTER TABLE invoices 
    ALTER COLUMN tenant_id SET NOT NULL,
    ALTER COLUMN amount SET NOT NULL,
    ALTER COLUMN created_at SET NOT NULL;

-- 2. UNIQUE constraints: users.email should be unique per tenant
ALTER TABLE users ADD CONSTRAINT unique_tenant_email UNIQUE (tenant_id, email);

-- 3. CHECK constraints
ALTER TABLE usage_logs ADD CONSTRAINT check_usage_count_positive CHECK (usage_count >= 0);
ALTER TABLE invoices ADD CONSTRAINT check_amount_positive CHECK (amount >= 0);

-- 4. FOREIGN KEY constraints with proper ON DELETE CASCADE where appropriate
ALTER TABLE users 
    ADD CONSTRAINT fk_users_tenant 
    FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id) ON DELETE CASCADE;

ALTER TABLE workspaces 
    ADD CONSTRAINT fk_workspaces_tenant 
    FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id) ON DELETE CASCADE;

ALTER TABLE applications 
    ADD CONSTRAINT fk_applications_workspace 
    FOREIGN KEY (workspace_id) REFERENCES workspaces(workspace_id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_applications_tenant 
    FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id) ON DELETE CASCADE;

ALTER TABLE usage_logs 
    ADD CONSTRAINT fk_usage_logs_tenant 
    FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_usage_logs_app 
    FOREIGN KEY (app_id) REFERENCES applications(app_id) ON DELETE CASCADE;

ALTER TABLE invoices 
    ADD CONSTRAINT fk_invoices_tenant 
    FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id) ON DELETE CASCADE;
