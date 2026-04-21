-- PART 2: triggers.sql
-- Updated to match actual schema.sql

-- 1. AUTO TIMESTAMP UPDATE
-- Automatically update updated_at column in users table before UPDATE
-- NOTE: updated_at column is not in current schema; this trigger will be skipped
-- Uncomment and add to schema if needed for audit trail
-- CREATE OR REPLACE FUNCTION update_updated_at_column()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     NEW.updated_at = CURRENT_TIMESTAMP;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
-- 
-- CREATE TRIGGER trg_users_updated_at
-- BEFORE UPDATE ON users
-- FOR EACH ROW
-- EXECUTE FUNCTION update_updated_at_column();


-- 2. AUDIT LOG SYSTEM
-- Automatic logging of INSERT operations to audit_logs
CREATE OR REPLACE FUNCTION log_insert_action()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_logs (tenant_id, actor, action, entity, created_at)
    VALUES (
        COALESCE(NEW.tenant_id, (SELECT id FROM tenants LIMIT 1)),
        'system',
        'INSERT',
        TG_TABLE_NAME,
        CURRENT_TIMESTAMP
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to log INSERT operations on users
CREATE TRIGGER trg_audit_users_insert
AFTER INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION log_insert_action();

-- Trigger to log INSERT operations on workspaces
CREATE TRIGGER trg_audit_workspaces_insert
AFTER INSERT ON workspaces
FOR EACH ROW
EXECUTE FUNCTION log_insert_action();

-- Trigger to log INSERT operations on deployments
CREATE TRIGGER trg_audit_deployments_insert
AFTER INSERT ON deployments
FOR EACH ROW
EXECUTE FUNCTION log_insert_action();


-- 3. RESOURCE USAGE VALIDATION TRIGGER
-- Prevent inserting negative api_calls or storage_mb in resource_usage
CREATE OR REPLACE FUNCTION validate_resource_usage()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.api_calls < 0 THEN
        RAISE EXCEPTION 'api_calls cannot be negative';
    END IF;
    IF NEW.storage_mb < 0 THEN
        RAISE EXCEPTION 'storage_mb cannot be negative';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_resource_usage
BEFORE INSERT OR UPDATE ON resource_usage
FOR EACH ROW
EXECUTE FUNCTION validate_resource_usage();
