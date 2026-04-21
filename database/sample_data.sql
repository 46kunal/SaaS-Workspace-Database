-- Sample data for SaaS Workspace Platform

-- 1. INSERT PLANS (Required for registration form)
INSERT INTO plans (name, price_per_month, api_limit, storage_limit_mb) VALUES
    ('Free', 0.00, 1000, 100),
    ('Pro', 49.00, 50000, 5000),
    ('Enterprise', 299.00, 1000000, 100000);

-- 2. INSERT TEST TENANTS
INSERT INTO tenants (name, domain, plan_id) VALUES
    ('Tenant A', 'tenant-a.com', 1),
    ('Tenant B', 'tenant-b.com', 2);
