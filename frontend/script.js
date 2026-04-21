/**
 * SaaS Workspace Frontend API Client
 */

const API_BASE = 'http://localhost:5000';

/**
 * API Client
 */
const api = {
    // =========================================================================
    // PLANS
    // =========================================================================

    async getPlans() {
        const res = await fetch(`${API_BASE}/invoices/plans`);
        if (!res.ok) throw new Error('Failed to fetch plans');
        return res.json();
    },

    async getPlan(planId) {
        const res = await fetch(`${API_BASE}/invoices/plans/${planId}`);
        if (!res.ok) throw new Error('Failed to fetch plan');
        return res.json();
    },

    // =========================================================================
    // TENANTS
    // =========================================================================

    async createTenant(name, domain, planId) {
        const res = await fetch(`${API_BASE}/tenants`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, domain, plan_id: planId })
        });
        if (!res.ok) {
            const err = await res.json();
            throw new Error(err.error || 'Failed to create tenant');
        }
        return res.json();
    },

    async getTenants() {
        const res = await fetch(`${API_BASE}/tenants`);
        if (!res.ok) throw new Error('Failed to fetch tenants');
        return res.json();
    },

    async getTenant(tenantId) {
        const res = await fetch(`${API_BASE}/tenants/${tenantId}`);
        if (!res.ok) throw new Error('Failed to fetch tenant');
        return res.json();
    },

    async updateTenant(tenantId, data) {
        const res = await fetch(`${API_BASE}/tenants/${tenantId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        if (!res.ok) throw new Error('Failed to update tenant');
        return res.json();
    },

    async deleteTenant(tenantId) {
        const res = await fetch(`${API_BASE}/tenants/${tenantId}`, {
            method: 'DELETE'
        });
        if (!res.ok) throw new Error('Failed to delete tenant');
        return res.json();
    },

    // =========================================================================
    // USERS
    // =========================================================================

    async createUser(tenantId, email, fullName, role = 'member') {
        const res = await fetch(`${API_BASE}/tenants/${tenantId}/users`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, full_name: fullName, role })
        });
        if (!res.ok) {
            const err = await res.json();
            throw new Error(err.error || 'Failed to create user');
        }
        return res.json();
    },

    async getUsers(tenantId) {
        const res = await fetch(`${API_BASE}/tenants/${tenantId}/users`);
        if (!res.ok) throw new Error('Failed to fetch users');
        return res.json();
    },

    async deleteUser(tenantId, userId) {
        const res = await fetch(`${API_BASE}/tenants/${tenantId}/users/${userId}`, {
            method: 'DELETE'
        });
        if (!res.ok) throw new Error('Failed to delete user');
        return res.json();
    },

    // =========================================================================
    // WORKSPACES
    // =========================================================================

    async createWorkspace(tenantId, name, createdBy) {
        const res = await fetch(`${API_BASE}/workspaces`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ tenant_id: tenantId, name, created_by: createdBy })
        });
        if (!res.ok) {
            const err = await res.json();
            throw new Error(err.error || 'Failed to create workspace');
        }
        return res.json();
    },

    async getWorkspaces(tenantId) {
        const res = await fetch(`${API_BASE}/workspaces?tenant_id=${tenantId}`);
        if (!res.ok) throw new Error('Failed to fetch workspaces');
        return res.json();
    },

    async getWorkspace(tenantId, workspaceId) {
        const res = await fetch(`${API_BASE}/workspaces/${workspaceId}?tenant_id=${tenantId}`);
        if (!res.ok) throw new Error('Failed to fetch workspace');
        return res.json();
    },

    async updateWorkspace(tenantId, workspaceId, name) {
        const res = await fetch(`${API_BASE}/workspaces/${workspaceId}?tenant_id=${tenantId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name })
        });
        if (!res.ok) throw new Error('Failed to update workspace');
        return res.json();
    },

    async deleteWorkspace(tenantId, workspaceId) {
        const res = await fetch(`${API_BASE}/workspaces/${workspaceId}?tenant_id=${tenantId}`, {
            method: 'DELETE'
        });
        if (!res.ok) throw new Error('Failed to delete workspace');
        return res.json();
    },

    // =========================================================================
    // DEPLOYMENTS
    // =========================================================================

    async createDeployment(tenantId, workspaceId, name, version, status = 'running') {
        const res = await fetch(`${API_BASE}/workspaces/${workspaceId}/deployments?tenant_id=${tenantId}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, version, status })
        });
        if (!res.ok) {
            const err = await res.json();
            throw new Error(err.error || 'Failed to create deployment');
        }
        return res.json();
    },

    async getDeployments(tenantId, workspaceId) {
        const res = await fetch(`${API_BASE}/workspaces/${workspaceId}/deployments?tenant_id=${tenantId}`);
        if (!res.ok) throw new Error('Failed to fetch deployments');
        return res.json();
    },

    async updateDeploymentStatus(tenantId, workspaceId, deploymentId, status) {
        const res = await fetch(`${API_BASE}/workspaces/${workspaceId}/deployments/${deploymentId}?tenant_id=${tenantId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ status })
        });
        if (!res.ok) throw new Error('Failed to update deployment');
        return res.json();
    },

    async deleteDeployment(tenantId, workspaceId, deploymentId) {
        const res = await fetch(`${API_BASE}/workspaces/${workspaceId}/deployments/${deploymentId}?tenant_id=${tenantId}`, {
            method: 'DELETE'
        });
        if (!res.ok) throw new Error('Failed to delete deployment');
        return res.json();
    },

    // =========================================================================
    // USAGE
    // =========================================================================

    async recordUsage(tenantId, workspaceId, apiCalls, storageMb, usageDate) {
        const res = await fetch(`${API_BASE}/usage`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                tenant_id: tenantId,
                workspace_id: workspaceId,
                api_calls: apiCalls,
                storage_mb: storageMb,
                usage_date: usageDate
            })
        });
        if (!res.ok) {
            const err = await res.json();
            throw new Error(err.error || 'Failed to record usage');
        }
        return res.json();
    },

    async getUsage(tenantId, startDate = null, endDate = null) {
        let url = `${API_BASE}/usage?tenant_id=${tenantId}`;
        if (startDate) url += `&start_date=${startDate}`;
        if (endDate) url += `&end_date=${endDate}`;

        const res = await fetch(url);
        if (!res.ok) throw new Error('Failed to fetch usage');
        return res.json();
    },

    async getUsageSummary(tenantId, startDate, endDate) {
        const res = await fetch(`${API_BASE}/usage/summary?tenant_id=${tenantId}&start_date=${startDate}&end_date=${endDate}`);
        if (!res.ok) throw new Error('Failed to fetch usage summary');
        return res.json();
    },

    // =========================================================================
    // INVOICES
    // =========================================================================

    async generateInvoice(tenantId, periodStart, periodEnd) {
        const res = await fetch(`${API_BASE}/invoices/generate`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                tenant_id: tenantId,
                period_start: periodStart,
                period_end: periodEnd
            })
        });
        if (!res.ok) {
            const err = await res.json();
            throw new Error(err.error || 'Failed to generate invoice');
        }
        return res.json();
    },

    async getInvoices(tenantId) {
        const res = await fetch(`${API_BASE}/invoices?tenant_id=${tenantId}`);
        if (!res.ok) throw new Error('Failed to fetch invoices');
        return res.json();
    },

    async getInvoice(tenantId, invoiceId) {
        const res = await fetch(`${API_BASE}/invoices/${invoiceId}?tenant_id=${tenantId}`);
        if (!res.ok) throw new Error('Failed to fetch invoice');
        return res.json();
    },

    async updateInvoiceStatus(tenantId, invoiceId, status) {
        const res = await fetch(`${API_BASE}/invoices/${invoiceId}?tenant_id=${tenantId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ status })
        });
        if (!res.ok) throw new Error('Failed to update invoice');
        return res.json();
    }
};

/**
 * Utility Functions
 */

function showAlert(containerId, message, type = 'info') {
    const container = document.getElementById(containerId);
    if (container) {
        container.innerHTML = `<div class="alert alert-${type}">${message}</div>`;
        setTimeout(() => {
            container.innerHTML = '';
        }, 5000);
    }
}

function formatDate(dateStr) {
    if (!dateStr) return '-';
    return new Date(dateStr).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    });
}

function formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
    }).format(amount);
}

function getCurrentTenantId() {
    return localStorage.getItem('currentTenantId');
}

function setCurrentTenantId(tenantId) {
    localStorage.setItem('currentTenantId', tenantId);
}

function getStatusBadgeClass(status) {
    const statusMap = {
        'running': 'badge-success',
        'stopped': 'badge-warning',
        'failed': 'badge-danger',
        'pending': 'badge-warning',
        'paid': 'badge-success',
        'overdue': 'badge-danger',
        'admin': 'badge-info',
        'member': 'badge-success',
        'viewer': 'badge-warning'
    };
    return statusMap[status] || 'badge-info';
}

/**
 * Health Check
 */
async function checkApiHealth() {
    try {
        const res = await fetch(`${API_BASE}/health`);
        return res.ok;
    } catch {
        return false;
    }
}
