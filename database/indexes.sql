-- ============================================================
--  SaaS Workspace Database
--  File: indexes.sql
--  Description: Strategic indexing for all core tables
--               Covers lookups, foreign keys, filtering,
--               and covering indexes for hot query paths
-- ============================================================


-- ============================================================
--  TABLE: workspaces
-- ============================================================

-- Fast lookup of all workspaces belonging to an owner
CREATE INDEX idx_workspaces_owner
    ON workspaces (owner_id);

-- Filter workspaces by subscription plan
CREATE INDEX idx_workspaces_plan
    ON workspaces (plan_id);

-- Composite: find active workspaces created after a date
CREATE INDEX idx_workspaces_created
    ON workspaces (created_at DESC);


-- ============================================================
--  TABLE: users
-- ============================================================

-- Login & uniqueness enforcement
CREATE UNIQUE INDEX uidx_users_email
    ON users (email);

-- Soft-delete or status filtering
CREATE INDEX idx_users_status
    ON users (status, created_at DESC);


-- ============================================================
--  TABLE: plans
-- ============================================================

-- Filter plans by billing cycle (monthly / annual)
CREATE INDEX idx_plans_billing_cycle
    ON plans (billing_cycle);

-- Covering index for plan-price queries (avoids table hit)
CREATE INDEX idx_plans_cover_price
    ON plans (id, name, price_per_seat, billing_cycle);


-- ============================================================
--  TABLE: workspace_users  (membership / seat table)
-- ============================================================

-- Primary lookup: all members of a workspace
CREATE INDEX idx_wu_workspace
    ON workspace_users (workspace_id, is_active);

-- Reverse lookup: all workspaces a user belongs to
CREATE INDEX idx_wu_user
    ON workspace_users (user_id, is_active);

-- Composite for billing cursor (used inside generate_invoice)
--   WHERE workspace_id = ? AND is_active = 1 AND joined_at <= ?
CREATE INDEX idx_wu_billing
    ON workspace_users (workspace_id, is_active, joined_at);

-- Role-based access queries
CREATE INDEX idx_wu_role
    ON workspace_users (workspace_id, role, is_active);


-- ============================================================
--  TABLE: invoices
-- ============================================================

-- Unique invoice number (human-readable reference)
CREATE UNIQUE INDEX uidx_invoices_number
    ON invoices (invoice_number);

-- Fetch all invoices for a workspace (most common read path)
CREATE INDEX idx_invoices_workspace
    ON invoices (workspace_id, created_at DESC);

-- Billing-period uniqueness per workspace
--   (mirrors duplicate-check in generate_invoice)
CREATE UNIQUE INDEX uidx_invoices_period
    ON invoices (workspace_id, billing_period_start, billing_period_end);

-- Payment dashboard: filter by status + due date
CREATE INDEX idx_invoices_status_due
    ON invoices (status, due_date);

-- Covering index for invoice list view (no table hit)
--   Columns: id, workspace_id, invoice_number, status, total_amount, due_date
CREATE INDEX idx_invoices_list_cover
    ON invoices (workspace_id, status, due_date, total_amount, invoice_number);

-- Created-by audit trail
CREATE INDEX idx_invoices_created_by
    ON invoices (created_by, created_at DESC);


-- ============================================================
--  TABLE: invoice_items
-- ============================================================

-- Primary lookup: all line items for an invoice
CREATE INDEX idx_invoice_items_invoice
    ON invoice_items (invoice_id);

-- Revenue reporting: sum amounts across invoices
--   Covering index so SUM(amount) needs no table hit
CREATE INDEX idx_invoice_items_cover
    ON invoice_items (invoice_id, amount);


-- ============================================================
--  TABLE: payments
-- ============================================================

-- Look up all payments for an invoice
CREATE INDEX idx_payments_invoice
    ON payments (invoice_id, status);

-- Financial reporting by date range
CREATE INDEX idx_payments_paid_at
    ON payments (paid_at DESC, status);

-- Payment method analytics
CREATE INDEX idx_payments_method
    ON payments (payment_method, paid_at DESC);

-- Covering index for payment reconciliation dashboard
CREATE INDEX idx_payments_reconcile
    ON payments (invoice_id, status, amount, paid_at);


-- ============================================================
--  FULL-TEXT SEARCH (optional – MySQL / MariaDB)
-- ============================================================
-- Enables fast keyword search across invoice items
CREATE FULLTEXT INDEX ft_invoice_items_desc
    ON invoice_items (description);

-- Workspace name search
CREATE FULLTEXT INDEX ft_workspaces_name
    ON workspaces (name);


-- ============================================================
--  VERIFICATION QUERIES
--  Run these after creation to confirm indexes are in place
-- ============================================================
/*
SHOW INDEX FROM workspaces;
SHOW INDEX FROM users;
SHOW INDEX FROM plans;
SHOW INDEX FROM workspace_users;
SHOW INDEX FROM invoices;
SHOW INDEX FROM invoice_items;
SHOW INDEX FROM payments;

-- Confirm the billing cursor path uses idx_wu_billing
EXPLAIN SELECT *
  FROM workspace_users
 WHERE workspace_id = 42
   AND is_active    = 1
   AND joined_at   <= '2025-04-30';

-- Confirm invoice list uses covering index
EXPLAIN SELECT id, invoice_number, status, total_amount, due_date
  FROM invoices
 WHERE workspace_id = 42
   AND status = 'pending'
 ORDER BY due_date;
*/
