-- ============================================================
--  SaaS Workspace Database
--  File: procedures.sql
--  Description: Stored procedure for invoice generation
--               with full transaction control
-- ============================================================

-- ------------------------------------------------------------
-- ASSUMED SCHEMA (ensure these tables exist before running)
-- ------------------------------------------------------------
-- workspaces       (id, name, owner_id, plan_id, created_at)
-- plans            (id, name, price_per_seat, billing_cycle)
-- workspace_users  (id, workspace_id, user_id, role, joined_at, is_active)
-- invoices         (id, workspace_id, invoice_number, status,
--                   subtotal, tax_rate, tax_amount, total_amount,
--                   billing_period_start, billing_period_end,
--                   due_date, created_at)
-- invoice_items    (id, invoice_id, description, quantity,
--                   unit_price, amount, created_at)
-- payments         (id, invoice_id, amount, status,
--                   payment_method, paid_at, created_at)
-- ------------------------------------------------------------


DELIMITER $$

-- ============================================================
--  HELPER FUNCTION: Generate a unique invoice number
--  Format: INV-YYYYMM-<workspace_id>-<sequence>
-- ============================================================
DROP FUNCTION IF EXISTS fn_next_invoice_number $$

CREATE FUNCTION fn_next_invoice_number(p_workspace_id INT)
RETURNS VARCHAR(40)
DETERMINISTIC
BEGIN
    DECLARE v_seq       INT DEFAULT 0;
    DECLARE v_ym        VARCHAR(6);
    DECLARE v_inv_no    VARCHAR(40);

    SET v_ym = DATE_FORMAT(NOW(), '%Y%m');

    -- Count existing invoices for this workspace in the current month
    SELECT COUNT(*) + 1
      INTO v_seq
      FROM invoices
     WHERE workspace_id          = p_workspace_id
       AND DATE_FORMAT(created_at, '%Y%m') = v_ym;

    SET v_inv_no = CONCAT('INV-', v_ym, '-', p_workspace_id, '-',
                          LPAD(v_seq, 4, '0'));
    RETURN v_inv_no;
END $$


-- ============================================================
--  STORED PROCEDURE: generate_invoice
--
--  Purpose  : Creates a complete invoice for a workspace
--             covering one billing period.
--
--  Parameters:
--    p_workspace_id   – workspace to bill
--    p_period_start   – billing period start  (YYYY-MM-DD)
--    p_period_end     – billing period end    (YYYY-MM-DD)
--    p_tax_rate       – tax percentage, e.g. 18.00 for 18 %
--    p_due_days       – days from today until payment is due
--    p_created_by     – user/system ID triggering the invoice
--
--  OUT Parameters:
--    p_invoice_id     – ID of the newly created invoice
--    p_status_msg     – human-readable result message
--
--  Transaction strategy:
--    • Single atomic transaction – all inserts succeed or all roll back.
--    • SAVEPOINT used before each invoice_item insert so a bad line
--      can be skipped without aborting the whole invoice.
--    • SIGNAL SQLSTATE raises application-level errors on bad input.
-- ============================================================
DROP PROCEDURE IF EXISTS generate_invoice $$

CREATE PROCEDURE generate_invoice (
    IN  p_workspace_id   INT,
    IN  p_period_start   DATE,
    IN  p_period_end     DATE,
    IN  p_tax_rate       DECIMAL(5,2),   -- e.g. 18.00
    IN  p_due_days       INT,            -- e.g. 30
    IN  p_created_by     INT,
    OUT p_invoice_id     INT,
    OUT p_status_msg     VARCHAR(255)
)
BEGIN
    -- ── Local variables ───────────────────────────────────────
    DECLARE v_plan_id           INT;
    DECLARE v_price_per_seat    DECIMAL(10,2);
    DECLARE v_billing_cycle     VARCHAR(20);
    DECLARE v_seat_count        INT;
    DECLARE v_invoice_number    VARCHAR(40);
    DECLARE v_subtotal          DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_tax_amount        DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_total             DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_due_date          DATE;
    DECLARE v_item_amount       DECIMAL(12,2);
    DECLARE v_done              INT DEFAULT 0;

    -- Cursor over billable line items (one row per active feature / seat group)
    DECLARE v_item_desc     VARCHAR(255);
    DECLARE v_item_qty      INT;
    DECLARE v_item_price    DECIMAL(10,2);

    DECLARE cur_items CURSOR FOR
        SELECT
            CONCAT(p.name, ' – seat for ', u.email)  AS description,
            1                                          AS quantity,
            p.price_per_seat                           AS unit_price
        FROM workspace_users wu
        JOIN workspaces  w  ON w.id  = wu.workspace_id
        JOIN plans       p  ON p.id  = w.plan_id
        JOIN users       u  ON u.id  = wu.user_id
        WHERE wu.workspace_id = p_workspace_id
          AND wu.is_active    = 1
          AND wu.joined_at   <= p_period_end;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    -- ── Error handler – rolls back everything on unexpected error ──
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_invoice_id  = NULL;
        SET p_status_msg  = 'ERROR: Unexpected failure – transaction rolled back.';
    END;

    -- ════════════════════════════════════════════════════════
    --  STEP 1 – Input validation (before opening transaction)
    -- ════════════════════════════════════════════════════════
    IF p_period_start >= p_period_end THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'period_start must be before period_end';
    END IF;

    IF p_tax_rate < 0 OR p_tax_rate > 100 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'tax_rate must be between 0 and 100';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM workspaces WHERE id = p_workspace_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'workspace not found';
    END IF;

    -- Check for a duplicate invoice in the same period
    IF EXISTS (
        SELECT 1 FROM invoices
         WHERE workspace_id         = p_workspace_id
           AND billing_period_start = p_period_start
           AND billing_period_end   = p_period_end
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invoice already exists for this workspace and billing period';
    END IF;

    -- ════════════════════════════════════════════════════════
    --  STEP 2 – Fetch plan & seat info
    -- ════════════════════════════════════════════════════════
    SELECT w.plan_id, p.price_per_seat, p.billing_cycle
      INTO v_plan_id, v_price_per_seat, v_billing_cycle
      FROM workspaces w
      JOIN plans      p ON p.id = w.plan_id
     WHERE w.id = p_workspace_id;

    SELECT COUNT(*)
      INTO v_seat_count
      FROM workspace_users
     WHERE workspace_id = p_workspace_id
       AND is_active    = 1
       AND joined_at   <= p_period_end;

    IF v_seat_count = 0 THEN
        SET p_invoice_id = NULL;
        SET p_status_msg = 'WARNING: No active seats found – invoice not created.';
        LEAVE generate_invoice_proc;  -- named label trick avoided; use LEAVE
    END IF;

    SET v_due_date       = DATE_ADD(CURDATE(), INTERVAL p_due_days DAY);
    SET v_invoice_number = fn_next_invoice_number(p_workspace_id);

    -- ════════════════════════════════════════════════════════
    --  STEP 3 – Open transaction
    -- ════════════════════════════════════════════════════════
    START TRANSACTION;

    -- ── 3a. Insert invoice header (status = 'draft') ──────
    INSERT INTO invoices (
        workspace_id,
        invoice_number,
        status,
        subtotal,
        tax_rate,
        tax_amount,
        total_amount,
        billing_period_start,
        billing_period_end,
        due_date,
        created_by,
        created_at
    ) VALUES (
        p_workspace_id,
        v_invoice_number,
        'draft',
        0.00,           -- updated after items are inserted
        p_tax_rate,
        0.00,
        0.00,
        p_period_start,
        p_period_end,
        v_due_date,
        p_created_by,
        NOW()
    );

    SET p_invoice_id = LAST_INSERT_ID();

    -- ── 3b. Insert line items via cursor ──────────────────
    OPEN cur_items;

    item_loop: LOOP
        FETCH cur_items INTO v_item_desc, v_item_qty, v_item_price;

        IF v_done = 1 THEN
            LEAVE item_loop;
        END IF;

        SET v_item_amount = v_item_qty * v_item_price;

        -- SAVEPOINT per item so a single bad row can be skipped
        SAVEPOINT sp_item;

        BEGIN
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            BEGIN
                ROLLBACK TO SAVEPOINT sp_item;
            END;

            INSERT INTO invoice_items (
                invoice_id,
                description,
                quantity,
                unit_price,
                amount,
                created_at
            ) VALUES (
                p_invoice_id,
                v_item_desc,
                v_item_qty,
                v_item_price,
                v_item_amount,
                NOW()
            );

            SET v_subtotal = v_subtotal + v_item_amount;
        END;

        RELEASE SAVEPOINT sp_item;
    END LOOP item_loop;

    CLOSE cur_items;

    -- ── 3c. Calculate totals and update invoice header ────
    SET v_tax_amount = ROUND(v_subtotal * p_tax_rate / 100, 2);
    SET v_total      = v_subtotal + v_tax_amount;

    UPDATE invoices
       SET subtotal     = v_subtotal,
           tax_amount   = v_tax_amount,
           total_amount = v_total,
           status       = 'pending'       -- promote from draft → pending
     WHERE id = p_invoice_id;

    -- ── 3d. Commit ────────────────────────────────────────
    COMMIT;

    SET p_status_msg = CONCAT(
        'SUCCESS: Invoice ', v_invoice_number,
        ' created (ID=', p_invoice_id, ')',
        ' | Seats=', v_seat_count,
        ' | Subtotal=', v_subtotal,
        ' | Tax(', p_tax_rate, '%)=', v_tax_amount,
        ' | Total=', v_total
    );

END $$

DELIMITER ;


-- ============================================================
--  USAGE EXAMPLE
-- ============================================================
/*
SET @inv_id = 0;
SET @msg    = '';

CALL generate_invoice(
    42,                  -- workspace_id
    '2025-04-01',        -- billing_period_start
    '2025-04-30',        -- billing_period_end
    18.00,               -- tax_rate (18 %)
    30,                  -- due in 30 days
    1,                   -- created_by (admin user id)
    @inv_id,             -- OUT: invoice id
    @msg                 -- OUT: status message
);

SELECT @inv_id AS invoice_id, @msg AS result;
*/
