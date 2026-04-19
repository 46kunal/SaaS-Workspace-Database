-- PART 2: triggers.sql

-- 1. AUTO TIMESTAMP UPDATE
-- Automatically update updated_at column in users table before UPDATE
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- 2. AUDIT LOG SYSTEM
-- Create a table audit_logs(log_id, action, table_name, timestamp)
CREATE TABLE IF NOT EXISTS audit_logs (
    log_id SERIAL PRIMARY KEY,
    action VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger function to log INSERT operations
CREATE OR REPLACE FUNCTION log_insert_action()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_logs (action, table_name, timestamp)
    VALUES ('INSERT', TG_TABLE_NAME, CURRENT_TIMESTAMP);
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


-- 3. USAGE VALIDATION TRIGGER
-- Prevent inserting negative usage_count in usage_logs
-- Raise exception if invalid
CREATE OR REPLACE FUNCTION validate_usage_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.usage_count < 0 THEN
        RAISE EXCEPTION 'usage_count cannot be negative';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_usage_logs
BEFORE INSERT OR UPDATE ON usage_logs
FOR EACH ROW
EXECUTE FUNCTION validate_usage_count();


-- 4. OPTIONAL (BONUS): Add trigger to log invoice creation
CREATE TRIGGER trg_audit_invoices_insert
AFTER INSERT ON invoices
FOR EACH ROW
EXECUTE FUNCTION log_insert_action();
