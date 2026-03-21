-- Placeholder table definitions (columns only, constraints to be added)

CREATE TABLE tenants (
	id SERIAL,
	name VARCHAR(150),
	domain VARCHAR(150),
	plan_id INTEGER,
	created_at TIMESTAMPTZ
);

CREATE TABLE plans (
	id SERIAL,
	name VARCHAR(100),
	price_per_month NUMERIC(10,2),
	api_limit INTEGER,
	storage_limit_mb NUMERIC(12,2),
	created_at TIMESTAMPTZ
);

CREATE TABLE users (
	id SERIAL,
	tenant_id INTEGER,
	email VARCHAR(200),
	full_name VARCHAR(200),
	role VARCHAR(50),
	created_at TIMESTAMPTZ
);

CREATE TABLE workspaces (
	id SERIAL,
	tenant_id INTEGER,
	name VARCHAR(150),
	created_by INTEGER,
	created_at TIMESTAMPTZ
);

CREATE TABLE deployments (
	id SERIAL,
	tenant_id INTEGER,
	workspace_id INTEGER,
	name VARCHAR(150),
	version VARCHAR(50),
	status VARCHAR(50),
	deployed_at TIMESTAMPTZ
);

CREATE TABLE resource_usage (
	id SERIAL,
	tenant_id INTEGER,
	workspace_id INTEGER,
	api_calls INTEGER,
	storage_mb NUMERIC(12,2),
	usage_date DATE,
	recorded_at TIMESTAMPTZ
);

CREATE TABLE invoices (
	id SERIAL,
	tenant_id INTEGER,
	plan_id INTEGER,
	period_start DATE,
	period_end DATE,
	total_amount NUMERIC(12,2),
	status VARCHAR(50),
	created_at TIMESTAMPTZ
);

CREATE TABLE audit_logs (
	id SERIAL,
	tenant_id INTEGER,
	actor VARCHAR(200),
	action VARCHAR(200),
	entity VARCHAR(100),
	details JSONB,
	created_at TIMESTAMPTZ
);
