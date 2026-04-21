"""Database queries for multi-tenant SaaS application.

All queries that access tenant-specific data include tenant_id filtering
to ensure proper data isolation between tenants.
"""

from db import get_db_cursor

# =============================================================================
# PLANS
# =============================================================================

def get_all_plans():
    """Fetch all available plans."""
    with get_db_cursor() as cur:
        cur.execute("SELECT id, name, price_per_month, api_limit, storage_limit_mb, created_at FROM plans")
        rows = cur.fetchall()
        return [
            {"id": r[0], "name": r[1], "price_per_month": float(r[2]),
             "api_limit": r[3], "storage_limit_mb": float(r[4]), "created_at": r[5]}
            for r in rows
        ]


def get_plan_by_id(plan_id: int):
    """Fetch a plan by ID."""
    with get_db_cursor() as cur:
        cur.execute(
            "SELECT id, name, price_per_month, api_limit, storage_limit_mb, created_at FROM plans WHERE id = %s",
            (plan_id,)
        )
        r = cur.fetchone()
        if r:
            return {"id": r[0], "name": r[1], "price_per_month": float(r[2]),
                    "api_limit": r[3], "storage_limit_mb": float(r[4]), "created_at": r[5]}
        return None


# =============================================================================
# TENANTS
# =============================================================================

def create_tenant(name: str, domain: str, plan_id: int):
    """Create a new tenant."""
    with get_db_cursor() as cur:
        cur.execute(
            """INSERT INTO tenants (name, domain, plan_id, created_at)
               VALUES (%s, %s, %s, NOW())
               RETURNING id, name, domain, plan_id, created_at""",
            (name, domain, plan_id)
        )
        r = cur.fetchone()
        return {"id": r[0], "name": r[1], "domain": r[2], "plan_id": r[3], "created_at": r[4]}


def get_all_tenants():
    """Fetch all tenants."""
    with get_db_cursor() as cur:
        cur.execute("SELECT id, name, domain, plan_id, created_at FROM tenants")
        rows = cur.fetchall()
        return [
            {"id": r[0], "name": r[1], "domain": r[2], "plan_id": r[3], "created_at": r[4]}
            for r in rows
        ]


def get_tenant_by_id(tenant_id: int):
    """Fetch a tenant by ID."""
    with get_db_cursor() as cur:
        cur.execute(
            "SELECT id, name, domain, plan_id, created_at FROM tenants WHERE id = %s",
            (tenant_id,)
        )
        r = cur.fetchone()
        if r:
            return {"id": r[0], "name": r[1], "domain": r[2], "plan_id": r[3], "created_at": r[4]}
        return None


def update_tenant(tenant_id: int, name: str = None, domain: str = None, plan_id: int = None):
    """Update a tenant's details."""
    updates = []
    values = []
    if name is not None:
        updates.append("name = %s")
        values.append(name)
    if domain is not None:
        updates.append("domain = %s")
        values.append(domain)
    if plan_id is not None:
        updates.append("plan_id = %s")
        values.append(plan_id)

    if not updates:
        return get_tenant_by_id(tenant_id)

    values.append(tenant_id)
    with get_db_cursor() as cur:
        cur.execute(
            f"UPDATE tenants SET {', '.join(updates)} WHERE id = %s RETURNING id, name, domain, plan_id, created_at",
            tuple(values)
        )
        r = cur.fetchone()
        if r:
            return {"id": r[0], "name": r[1], "domain": r[2], "plan_id": r[3], "created_at": r[4]}
        return None


def delete_tenant(tenant_id: int):
    """Delete a tenant."""
    with get_db_cursor() as cur:
        cur.execute("DELETE FROM tenants WHERE id = %s RETURNING id", (tenant_id,))
        return cur.fetchone() is not None


# =============================================================================
# USERS (Multi-tenant: filtered by tenant_id)
# =============================================================================

def create_user(tenant_id: int, email: str, full_name: str, role: str = "member"):
    """Create a new user for a tenant."""
    with get_db_cursor() as cur:
        cur.execute(
            """INSERT INTO users (tenant_id, email, full_name, role, created_at)
               VALUES (%s, %s, %s, %s, NOW())
               RETURNING id, tenant_id, email, full_name, role, created_at""",
            (tenant_id, email, full_name, role)
        )
        r = cur.fetchone()
        return {"id": r[0], "tenant_id": r[1], "email": r[2], "full_name": r[3], "role": r[4], "created_at": r[5]}


def get_users_by_tenant(tenant_id: int):
    """Fetch all users for a tenant."""
    with get_db_cursor() as cur:
        cur.execute(
            "SELECT id, tenant_id, email, full_name, role, created_at FROM users WHERE tenant_id = %s",
            (tenant_id,)
        )
        rows = cur.fetchall()
        return [
            {"id": r[0], "tenant_id": r[1], "email": r[2], "full_name": r[3], "role": r[4], "created_at": r[5]}
            for r in rows
        ]


def get_user_by_id(tenant_id: int, user_id: int):
    """Fetch a user by ID (scoped to tenant)."""
    with get_db_cursor() as cur:
        cur.execute(
            "SELECT id, tenant_id, email, full_name, role, created_at FROM users WHERE id = %s AND tenant_id = %s",
            (user_id, tenant_id)
        )
        r = cur.fetchone()
        if r:
            return {"id": r[0], "tenant_id": r[1], "email": r[2], "full_name": r[3], "role": r[4], "created_at": r[5]}
        return None


def delete_user(tenant_id: int, user_id: int):
    """Delete a user (scoped to tenant)."""
    with get_db_cursor() as cur:
        cur.execute("DELETE FROM users WHERE id = %s AND tenant_id = %s RETURNING id", (user_id, tenant_id))
        return cur.fetchone() is not None


# =============================================================================
# WORKSPACES (Multi-tenant: filtered by tenant_id)
# =============================================================================

def create_workspace(tenant_id: int, name: str, created_by: int = None):
    """Create a new workspace for a tenant."""
    with get_db_cursor() as cur:
        cur.execute(
            """INSERT INTO workspaces (tenant_id, name, created_by, created_at)
               VALUES (%s, %s, %s, NOW())
               RETURNING id, tenant_id, name, created_by, created_at""",
            (tenant_id, name, created_by)
        )
        r = cur.fetchone()
        return {"id": r[0], "tenant_id": r[1], "name": r[2], "created_by": r[3], "created_at": r[4]}


def get_workspaces_by_tenant(tenant_id: int):
    """Fetch all workspaces for a tenant."""
    with get_db_cursor() as cur:
        cur.execute(
            "SELECT id, tenant_id, name, created_by, created_at FROM workspaces WHERE tenant_id = %s",
            (tenant_id,)
        )
        rows = cur.fetchall()
        return [
            {"id": r[0], "tenant_id": r[1], "name": r[2], "created_by": r[3], "created_at": r[4]}
            for r in rows
        ]


def get_workspace_by_id(tenant_id: int, workspace_id: int):
    """Fetch a workspace by ID (scoped to tenant)."""
    with get_db_cursor() as cur:
        cur.execute(
            "SELECT id, tenant_id, name, created_by, created_at FROM workspaces WHERE id = %s AND tenant_id = %s",
            (workspace_id, tenant_id)
        )
        r = cur.fetchone()
        if r:
            return {"id": r[0], "tenant_id": r[1], "name": r[2], "created_by": r[3], "created_at": r[4]}
        return None


def update_workspace(tenant_id: int, workspace_id: int, name: str):
    """Update a workspace name (scoped to tenant)."""
    with get_db_cursor() as cur:
        cur.execute(
            "UPDATE workspaces SET name = %s WHERE id = %s AND tenant_id = %s RETURNING id, tenant_id, name, created_by, created_at",
            (name, workspace_id, tenant_id)
        )
        r = cur.fetchone()
        if r:
            return {"id": r[0], "tenant_id": r[1], "name": r[2], "created_by": r[3], "created_at": r[4]}
        return None


def delete_workspace(tenant_id: int, workspace_id: int):
    """Delete a workspace (scoped to tenant)."""
    with get_db_cursor() as cur:
        cur.execute("DELETE FROM workspaces WHERE id = %s AND tenant_id = %s RETURNING id", (workspace_id, tenant_id))
        return cur.fetchone() is not None


# =============================================================================
# DEPLOYMENTS (Multi-tenant: filtered by tenant_id)
# =============================================================================

def create_deployment(tenant_id: int, workspace_id: int, name: str, version: str, status: str = "running"):
    """Create a new deployment."""
    with get_db_cursor() as cur:
        cur.execute(
            """INSERT INTO deployments (tenant_id, workspace_id, name, version, status, deployed_at)
               VALUES (%s, %s, %s, %s, %s, NOW())
               RETURNING id, tenant_id, workspace_id, name, version, status, deployed_at""",
            (tenant_id, workspace_id, name, version, status)
        )
        r = cur.fetchone()
        return {"id": r[0], "tenant_id": r[1], "workspace_id": r[2], "name": r[3],
                "version": r[4], "status": r[5], "deployed_at": r[6]}


def get_deployments_by_tenant(tenant_id: int):
    """Fetch all deployments for a tenant."""
    with get_db_cursor() as cur:
        cur.execute(
            "SELECT id, tenant_id, workspace_id, name, version, status, deployed_at FROM deployments WHERE tenant_id = %s",
            (tenant_id,)
        )
        rows = cur.fetchall()
        return [
            {"id": r[0], "tenant_id": r[1], "workspace_id": r[2], "name": r[3],
             "version": r[4], "status": r[5], "deployed_at": r[6]}
            for r in rows
        ]


def get_deployments_by_workspace(tenant_id: int, workspace_id: int):
    """Fetch all deployments for a workspace (scoped to tenant)."""
    with get_db_cursor() as cur:
        cur.execute(
            "SELECT id, tenant_id, workspace_id, name, version, status, deployed_at FROM deployments WHERE tenant_id = %s AND workspace_id = %s",
            (tenant_id, workspace_id)
        )
        rows = cur.fetchall()
        return [
            {"id": r[0], "tenant_id": r[1], "workspace_id": r[2], "name": r[3],
             "version": r[4], "status": r[5], "deployed_at": r[6]}
            for r in rows
        ]


def update_deployment_status(tenant_id: int, deployment_id: int, status: str):
    """Update a deployment's status (scoped to tenant)."""
    with get_db_cursor() as cur:
        cur.execute(
            "UPDATE deployments SET status = %s WHERE id = %s AND tenant_id = %s RETURNING id, tenant_id, workspace_id, name, version, status, deployed_at",
            (status, deployment_id, tenant_id)
        )
        r = cur.fetchone()
        if r:
            return {"id": r[0], "tenant_id": r[1], "workspace_id": r[2], "name": r[3],
                    "version": r[4], "status": r[5], "deployed_at": r[6]}
        return None


def delete_deployment(tenant_id: int, deployment_id: int):
    """Delete a deployment (scoped to tenant)."""
    with get_db_cursor() as cur:
        cur.execute("DELETE FROM deployments WHERE id = %s AND tenant_id = %s RETURNING id", (deployment_id, tenant_id))
        return cur.fetchone() is not None


# =============================================================================
# RESOURCE USAGE (Multi-tenant: filtered by tenant_id)
# =============================================================================

def record_usage(tenant_id: int, workspace_id: int, api_calls: int, storage_mb: float, usage_date: str):
    """Record resource usage for a tenant/workspace."""
    with get_db_cursor() as cur:
        cur.execute(
            """INSERT INTO resource_usage (tenant_id, workspace_id, api_calls, storage_mb, usage_date, recorded_at)
               VALUES (%s, %s, %s, %s, %s, NOW())
               RETURNING id, tenant_id, workspace_id, api_calls, storage_mb, usage_date, recorded_at""",
            (tenant_id, workspace_id, api_calls, storage_mb, usage_date)
        )
        r = cur.fetchone()
        return {"id": r[0], "tenant_id": r[1], "workspace_id": r[2], "api_calls": r[3],
                "storage_mb": float(r[4]), "usage_date": r[5], "recorded_at": r[6]}


def get_usage_by_tenant(tenant_id: int, start_date: str = None, end_date: str = None):
    """Fetch usage records for a tenant, optionally filtered by date range."""
    query = "SELECT id, tenant_id, workspace_id, api_calls, storage_mb, usage_date, recorded_at FROM resource_usage WHERE tenant_id = %s"
    params = [tenant_id]

    if start_date:
        query += " AND usage_date >= %s"
        params.append(start_date)
    if end_date:
        query += " AND usage_date <= %s"
        params.append(end_date)

    query += " ORDER BY usage_date DESC"

    with get_db_cursor() as cur:
        cur.execute(query, tuple(params))
        rows = cur.fetchall()
        return [
            {"id": r[0], "tenant_id": r[1], "workspace_id": r[2], "api_calls": r[3],
             "storage_mb": float(r[4]), "usage_date": r[5], "recorded_at": r[6]}
            for r in rows
        ]


def get_usage_summary(tenant_id: int, start_date: str, end_date: str):
    """Get aggregated usage summary for a tenant."""
    with get_db_cursor() as cur:
        cur.execute(
            """SELECT COALESCE(SUM(api_calls), 0), COALESCE(SUM(storage_mb), 0)
               FROM resource_usage
               WHERE tenant_id = %s AND usage_date >= %s AND usage_date <= %s""",
            (tenant_id, start_date, end_date)
        )
        r = cur.fetchone()
        return {"total_api_calls": int(r[0]), "total_storage_mb": float(r[1])}


# =============================================================================
# INVOICES (Multi-tenant: filtered by tenant_id)
# =============================================================================

def get_invoices_by_tenant(tenant_id: int):
    """Fetch all invoices for a tenant."""
    with get_db_cursor() as cur:
        cur.execute(
            """SELECT id, tenant_id, plan_id, period_start, period_end, total_amount, status, created_at
               FROM invoices WHERE tenant_id = %s ORDER BY created_at DESC""",
            (tenant_id,)
        )
        rows = cur.fetchall()
        return [
            {"id": r[0], "tenant_id": r[1], "plan_id": r[2], "period_start": r[3],
             "period_end": r[4], "total_amount": float(r[5]), "status": r[6], "created_at": r[7]}
            for r in rows
        ]


def get_invoice_by_id(tenant_id: int, invoice_id: int):
    """Fetch an invoice by ID (scoped to tenant)."""
    with get_db_cursor() as cur:
        cur.execute(
            """SELECT id, tenant_id, plan_id, period_start, period_end, total_amount, status, created_at
               FROM invoices WHERE id = %s AND tenant_id = %s""",
            (invoice_id, tenant_id)
        )
        r = cur.fetchone()
        if r:
            return {"id": r[0], "tenant_id": r[1], "plan_id": r[2], "period_start": r[3],
                    "period_end": r[4], "total_amount": float(r[5]), "status": r[6], "created_at": r[7]}
        return None


def generate_invoice(tenant_id: int, period_start: str, period_end: str):
    """Call the stored procedure to generate an invoice.

    Note: This calls Om's generate_invoice procedure.
    """
    with get_db_cursor() as cur:
        cur.execute(
            "SELECT * FROM generate_invoice(%s, %s, %s, %s)",
            (tenant_id, period_start, period_end, "system")
        )
        cur.fetchone()
        # Fetch the newly created invoice
        cur.execute(
            """SELECT id, tenant_id, plan_id, period_start, period_end, total_amount, status, created_at
               FROM invoices WHERE tenant_id = %s AND period_start = %s AND period_end = %s
               ORDER BY created_at DESC LIMIT 1""",
            (tenant_id, period_start, period_end)
        )
        r = cur.fetchone()
        if r:
            return {"id": r[0], "tenant_id": r[1], "plan_id": r[2], "period_start": r[3],
                    "period_end": r[4], "total_amount": float(r[5]), "status": r[6], "created_at": r[7]}
        return None


def update_invoice_status(tenant_id: int, invoice_id: int, status: str):
    """Update an invoice's status (scoped to tenant)."""
    with get_db_cursor() as cur:
        cur.execute(
            """UPDATE invoices SET status = %s WHERE id = %s AND tenant_id = %s
               RETURNING id, tenant_id, plan_id, period_start, period_end, total_amount, status, created_at""",
            (status, invoice_id, tenant_id)
        )
        r = cur.fetchone()
        if r:
            return {"id": r[0], "tenant_id": r[1], "plan_id": r[2], "period_start": r[3],
                    "period_end": r[4], "total_amount": float(r[5]), "status": r[6], "created_at": r[7]}
        return None


# =============================================================================
# AUDIT LOGS (Multi-tenant: filtered by tenant_id)
# =============================================================================

def get_audit_logs_by_tenant(tenant_id: int, limit: int = 100):
    """Fetch audit logs for a tenant."""
    with get_db_cursor() as cur:
        cur.execute(
            """SELECT id, tenant_id, actor, action, entity, details, created_at
               FROM audit_logs WHERE tenant_id = %s ORDER BY created_at DESC LIMIT %s""",
            (tenant_id, limit)
        )
        rows = cur.fetchall()
        return [
            {"id": r[0], "tenant_id": r[1], "actor": r[2], "action": r[3],
             "entity": r[4], "details": r[5], "created_at": r[6]}
            for r in rows
        ]
