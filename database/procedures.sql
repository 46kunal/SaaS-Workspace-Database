-- ============================================================
--  SaaS Workspace Database
--  File: procedures.sql
--  Description: generate_invoice stored procedure
--               Written for PostgreSQL, matches schema.sql exactly
-- ============================================================


-- ============================================================
--  STORED FUNCTION: generate_invoice
--
--  What it does:
--    1. Validates input (tenant exists, dates valid, no duplicate)
--    2. Fetches the tenant's plan price from plans table
--    3. Calculates overages from resource_usage table
--    4. Inserts a new row into invoices table
--    5. Logs the action in audit_logs table
--    All inside one transaction — auto rolls back on any failure.
--
--  Parameters:
--    p_tenant_id     – which tenant to bill
--    p_period_start  – billing period start (YYYY-MM-DD)
--    p_period_end    – billing period end   (YYYY-MM-DD)
--    p_actor         – who triggered this (e.g. 'system' or user email)
--
--  Returns:
--    invoice_id      – id of the created invoice
--    status_msg      – human-readable result
-- ============================================================

CREATE OR REPLACE FUNCTION generate_invoice(
    p_tenant_id     INTEGER,
    p_period_start  DATE,
    p_period_end    DATE,
    p_actor         VARCHAR(200)
)
RETURNS TABLE (invoice_id INTEGER, status_msg TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_plan_id           INTEGER;
    v_plan_name         VARCHAR(100);
    v_price_per_month   NUMERIC(12,2);
    v_api_limit         INTEGER;
    v_storage_limit     NUMERIC(12,2);

    v_total_api_calls   INTEGER;
    v_total_storage     NUMERIC(12,2);
    v_overage_charge    NUMERIC(12,2) := 0.00;
    v_total_amount      NUMERIC(12,2);

    v_invoice_id        INTEGER;
    v_overage_rate      NUMERIC(10,4) := 0.001;  -- $0.001 per extra API call
    v_storage_rate      NUMERIC(10,4) := 0.05;   -- $0.05  per extra MB
BEGIN

    -- ══════════════════════════════════════════════════════
    --  STEP 1 — Validate inputs
    -- ══════════════════════════════════════════════════════

    -- Check tenant exists and has a plan assigned
    SELECT t.plan_id, p.name, p.price_per_month, p.api_limit, p.storage_limit_mb
      INTO v_plan_id, v_plan_name, v_price_per_month, v_api_limit, v_storage_limit
      FROM tenants t
      JOIN plans   p ON p.id = t.plan_id
     WHERE t.id = p_tenant_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tenant % not found or has no active plan assigned', p_tenant_id;
    END IF;

    -- Date sanity check
    IF p_period_start >= p_period_end THEN
        RAISE EXCEPTION 'period_start must be before period_end';
    END IF;

    -- Duplicate invoice guard (same tenant + same period = blocked)
    IF EXISTS (
        SELECT 1 FROM invoices
         WHERE tenant_id    = p_tenant_id
           AND period_start = p_period_start
           AND period_end   = p_period_end
    ) THEN
        RAISE EXCEPTION 'Invoice already exists for tenant % covering this period', p_tenant_id;
    END IF;

    -- ══════════════════════════════════════════════════════
    --  STEP 2 — Pull usage data from resource_usage
    --           and calculate any overage charges
    -- ══════════════════════════════════════════════════════

    SELECT
        COALESCE(SUM(ru.api_calls),  0),
        COALESCE(SUM(ru.storage_mb), 0.00)
      INTO v_total_api_calls, v_total_storage
      FROM resource_usage ru
     WHERE ru.tenant_id  = p_tenant_id
       AND ru.usage_date >= p_period_start
       AND ru.usage_date <= p_period_end;

    -- API call overage
    IF v_total_api_calls > v_api_limit THEN
        v_overage_charge := v_overage_charge +
            ((v_total_api_calls - v_api_limit) * v_overage_rate);
    END IF;

    -- Storage overage
    IF v_total_storage > v_storage_limit THEN
        v_overage_charge := v_overage_charge +
            ((v_total_storage - v_storage_limit) * v_storage_rate);
    END IF;

    -- Final total
    v_total_amount := v_price_per_month + v_overage_charge;

    -- ══════════════════════════════════════════════════════
    --  STEP 3 — Insert into invoices
    --  (PL/pgSQL runs inside a transaction automatically.
    --   Any RAISE EXCEPTION above rolls everything back.)
    -- ══════════════════════════════════════════════════════

    INSERT INTO invoices (
        tenant_id,
        plan_id,
        period_start,
        period_end,
        total_amount,
        status,
        created_at
    ) VALUES (
        p_tenant_id,
        v_plan_id,
        p_period_start,
        p_period_end,
        v_total_amount,
        'unpaid',
        CURRENT_TIMESTAMP
    )
    RETURNING id INTO v_invoice_id;

    -- ══════════════════════════════════════════════════════
    --  STEP 4 — Log to audit_logs (uses JSONB details column)
    -- ══════════════════════════════════════════════════════

    INSERT INTO audit_logs (
        tenant_id,
        actor,
        action,
        entity,
        details,
        created_at
    ) VALUES (
        p_tenant_id,
        p_actor,
        'generate_invoice',
        'invoices',
        jsonb_build_object(
            'invoice_id',        v_invoice_id,
            'plan',              v_plan_name,
            'period_start',      p_period_start,
            'period_end',        p_period_end,
            'base_price',        v_price_per_month,
            'overage_charge',    v_overage_charge,
            'total_amount',      v_total_amount,
            'api_calls_used',    v_total_api_calls,
            'api_limit',         v_api_limit,
            'storage_used_mb',   v_total_storage,
            'storage_limit_mb',  v_storage_limit
        ),
        CURRENT_TIMESTAMP
    );

    -- ══════════════════════════════════════════════════════
    --  STEP 5 — Return success result
    -- ══════════════════════════════════════════════════════

    RETURN QUERY SELECT
        v_invoice_id,
        FORMAT(
            'SUCCESS: Invoice #%s | Plan: %s | Base: $%s | Overage: $%s | Total: $%s',
            v_invoice_id,
            v_plan_name,
            v_price_per_month,
            v_overage_charge,
            v_total_amount
        )::TEXT;

EXCEPTION
    WHEN OTHERS THEN
        RAISE;  -- re-raise so transaction auto-rolls back
END;
$$;


-- ============================================================
--  USAGE EXAMPLE
-- ============================================================
/*
SELECT * FROM generate_invoice(
    1,              -- tenant_id
    '2025-04-01',   -- period_start
    '2025-04-30',   -- period_end
    'system'        -- actor (who triggered it)
);

-- Expected output:
--  invoice_id | status_msg
-- ------------+----------------------------------------------------
--           1 | SUCCESS: Invoice #1 | Plan: Pro | Base: $49.00 | ...
*/
