# SaaS Platform - End-to-End Flow

## 1. Tenant Registration Flow

```
User visits index.html
    ↓
Selects plan (Free/Pro/Enterprise) from dropdown
    ↓
Fills in:
  - Organization Name
  - Domain
  - Admin Email
  - Admin Full Name
    ↓
Frontend calls: POST /tenants
  {
    "name": "Acme Corp",
    "domain": "acme.com",
    "plan_id": 2
  }
    ↓
Backend (tenant.py):
  - Validates input
  - Creates tenant row in DB
  - Returns tenant_id
    ↓
Frontend calls: POST /tenants/{id}/users (create admin user)
  {
    "email": "admin@acme.com",
    "full_name": "John Doe",
    "role": "admin"
  }
    ↓
Backend (tenant.py):
  - Creates user row with tenant_id
  - Returns user_id
    ↓
Frontend stores tenant_id in localStorage
    ↓
Redirects to dashboard.html
```

## 2. Dashboard - Workspace Management Flow

```
User logs into dashboard
    ↓
Frontend loads tenant data:
  - Tenant name
  - List of workspaces
  - List of users
  - List of invoices
  - Usage stats
    ↓
Backend calls:
  - GET /tenants/{id}
  - GET /workspaces?tenant_id=X
  - GET /tenants/{id}/users
  - GET /invoices?tenant_id=X
  - GET /usage/summary?tenant_id=X&start_date=...&end_date=...
    ↓
Display on dashboard cards:
  - "Workspaces: 5"
  - "Deployments: 12"
  - "API Calls (Month): 145,230"
  - "Storage Used: 245.5 MB"
```

## 3. Creating a Workspace Flow

```
User clicks "+ New" workspace button
    ↓
Modal opens: "Create Workspace"
    ↓
User enters workspace name (e.g., "Production")
    ↓
Frontend calls: POST /workspaces
  {
    "tenant_id": 1,
    "name": "Production",
    "created_by": 1  (user_id of admin)
  }
    ↓
Backend (workspace.py):
  - Validates tenant_id matches logged-in user's tenant
  - Inserts into workspaces table
  - Returns workspace_id
    ↓
Database:
  - workspace row created with tenant_id = 1
  - Triggers log_insert_action fires
  - Audit_logs row created: action="INSERT", entity="workspaces"
    ↓
Frontend refreshes workspace list
    ↓
New workspace appears in dashboard
```

## 4. Tracking Resource Usage Flow

```
Application is running in production
    ↓
Application calls: POST /usage
  {
    "tenant_id": 1,
    "workspace_id": 5,
    "api_calls": 1250,
    "storage_mb": 45.75,
    "usage_date": "2026-04-21"
  }
    ↓
Backend (usage.py):
  - Validates all fields
  - Inserts into resource_usage table
  - Returns usage record
    ↓
Database:
  - resource_usage row inserted
  - Trigger validate_resource_usage fires
  - Checks: api_calls >= 0 AND storage_mb >= 0
  - Unique constraint enforced: only 1 record per workspace per day
    ↓
Usage data accumulated throughout the month
```

## 5. Invoice Generation Flow (CRITICAL)

```
Admin clicks "Generate Invoice" button
    ↓
Modal opens: date range picker
  - Default: Current month (e.g., 2026-04-01 to 2026-04-30)
    ↓
User clicks "Generate"
    ↓
Frontend calls: POST /invoices/generate
  {
    "tenant_id": 1,
    "period_start": "2026-04-01",
    "period_end": "2026-04-30"
  }
    ↓
Backend (billing.py):
  - Validates inputs
  - Calls: queries.generate_invoice(1, "2026-04-01", "2026-04-30", "system")
    ↓
Database - Stored Procedure (generate_invoice):
  
  STEP 1: Validate Inputs
    - Check tenant 1 exists
    - Check tenant has plan assigned
    - Check dates are valid (start < end)
    - Check no duplicate invoice for this period
  
  STEP 2: Fetch Plan & Calculate Overages
    - Get plan: Pro ($49/month, 50k API limit, 5GB storage limit)
    - Query resource_usage for April 1-30:
      - Total API calls: 150,000
      - Total storage: 7,000 MB
    - Calculate overages:
      - API overage: (150k - 50k) × $0.001 = $100
      - Storage overage: (7GB - 5GB) × $0.05 = $100
      - Total overage: $200
  
  STEP 3: Calculate Total Invoice Amount
    - Base: $49
    - Overage: $200
    - **Total: $249**
  
  STEP 4: Insert Invoice
    - INSERT into invoices table:
      - tenant_id: 1
      - plan_id: 2
      - period_start: "2026-04-01"
      - period_end: "2026-04-30"
      - total_amount: 249.00
      - status: "unpaid"
      - created_at: CURRENT_TIMESTAMP
    - Trigger trg_audit_invoices_insert fires
    - Audit log created: "Invoice generated for tenant 1"
  
  STEP 5: Return Result
    - All-or-nothing transaction
    - If any error: ROLLBACK entire transaction
    - Return: invoice_id, status_msg with full breakdown
    ↓
Backend returns invoice record
    ↓
Frontend displays:
  - Invoice #42
  - Period: April 1 - April 30, 2026
  - Base Fee: $49.00
  - Overage Charges: $200.00
  - Total: $249.00
  - Status: Unpaid
    ↓
Admin can click "Mark Paid" to update status to "paid"
```

## 6. Invoice Status Tracking Flow

```
Invoice created with status = "unpaid"
    ↓
Admin clicks "Mark Paid"
    ↓
Frontend calls: PUT /invoices/{id}?tenant_id=1
  {
    "status": "paid"
  }
    ↓
Backend (billing.py):
  - Validates status is one of: pending, paid, overdue
  - Updates invoice.status = "paid"
  - Returns updated invoice
    ↓
Database:
  - UPDATE invoices SET status='paid' WHERE id=42 AND tenant_id=1
    ↓
Frontend refreshes invoice list
    ↓
Invoice now shows status: "Paid" (green badge)
```

## 7. Audit & Compliance Flow

```
Every INSERT operation triggers audit logging:
    ↓
Trigger (log_insert_action):
  - Fires on INSERT to: users, workspaces, deployments
  - Also fires on invoice generation (stored procedure logs details)
    ↓
Audit log records:
  - tenant_id (who's data)
  - actor (who did it: e.g., "system", "admin@acme.com")
  - action (what: "INSERT", "generate_invoice")
  - entity (where: "users", "invoices")
  - details (JSONB: full record of what was created)
  - created_at (when)
    ↓
Admin can query: GET /audit_logs?tenant_id=1
    ↓
Backend returns all audit events for that tenant
    ↓
Full compliance trail for billing audits, user management, etc.
```

## Key Multi-Tenancy Enforcement Points

### 1. Database Level
- Every query filters by `tenant_id`
- Example: `SELECT * FROM users WHERE tenant_id = %s`
- Unique constraint: `(tenant_id, email)` on users
- Unique constraint: `(workspace_id, usage_date)` on resource_usage

### 2. Backend Level
- All endpoints verify `tenant_id` from request (query params or body)
- All queries scoped to that tenant_id
- FK constraints ensure data integrity

### 3. Frontend Level
- Stores `currentTenantId` in localStorage
- Passes it with every API call
- Only displays data for current tenant

### 4. Audit Trail
- Every action logged with tenant_id
- Compliance audits can prove data isolation

---

## Performance Considerations

### Indexes
- `idx_users_tenant`: Fast user lookups by tenant
- `idx_workspaces_tenant_status`: Fast workspace filtering
- `idx_resource_usage_date`: Fast usage date range queries
- `idx_invoices_period`: Fast invoice lookup by period

### Query Optimization
```sql
-- All queries use indexes:
SELECT * FROM users 
WHERE tenant_id = 1 AND email = 'user@example.com';
  -- Uses: idx_users_tenant (tenant_id), then searches email

SELECT * FROM resource_usage 
WHERE tenant_id = 1 AND usage_date BETWEEN '2026-04-01' AND '2026-04-30'
  -- Uses: idx_resource_usage_date for range scan
```

### Scaling
- Add more database replicas for read-heavy workloads
- Use connection pooling (already implemented in backend/db.py)
- Archive old audit_logs to separate cold storage

---

## Error Handling & Recovery

```
If invoice generation fails:
  - Database transaction rolls back automatically
  - No partial invoice created
  - Frontend receives error message
  - User can retry

If network drops during registration:
  - Tenant created but user not created (partial state)
  - Manual intervention: DELETE FROM tenants WHERE name = '...' 
    (cascades delete all related records)
  - User can retry from beginning
```

---

**Last Updated**: April 21, 2026
