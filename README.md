# SaaS Workspace Platform

Multi-tenant SaaS/DBMS simulation built with PostgreSQL, Flask, and a plain HTML/CSS/JS frontend. It models tenant registration, workspace management, user management, usage tracking, billing, and audit logging in a single shared database with tenant-based isolation.

## What It Does

The app lets you:
- Register a tenant and create an admin user
- Switch between tenants in the browser
- Manage workspaces and deployments
- Add team members with custom roles
- Record and inspect usage events
- Generate and update invoices
- Edit tenant settings or delete a tenant cleanly

The frontend is now split into separate pages so each workflow stays readable:
- [dashboard.html](frontend/dashboard.html) for tenant overview
- [workspaces.html](frontend/workspaces.html) for workspaces and deployments
- [users.html](frontend/users.html) for users and roles
- [usage.html](frontend/usage.html) for usage history and logging
- [invoices.html](frontend/invoices.html) for billing
- [settings.html](frontend/settings.html) for tenant settings

## Architecture

```text
Frontend (HTML/CSS/JS)
  ├─ index.html        tenant registration
  ├─ dashboard.html    tenant overview hub
  ├─ workspaces.html   workspaces + deployments
  ├─ users.html        users + roles
  ├─ usage.html        usage entry + reporting
  ├─ invoices.html     billing + invoice generation
  └─ settings.html    tenant profile + delete tenant
         │
         ▼
Flask backend
  ├─ /tenants
  ├─ /tenants/{id}/users
  ├─ /workspaces
  ├─ /usage
  └─ /invoices
         │
         ▼
PostgreSQL
  ├─ plans
  ├─ tenants
  ├─ users
  ├─ workspaces
  ├─ deployments
  ├─ resource_usage
  ├─ invoices
  └─ audit_logs
```

## Requirements

### Runtime
- Python 3.13 or compatible 3.8+
- PostgreSQL 18 or compatible 12+
- A modern browser

### Python Packages
Installed through [requirements.txt](requirements.txt):
- Flask
- Flask-CORS
- psycopg2-binary
- python-dotenv

### Environment Variables
Create a `.env` file with:
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=saas_workspace
DB_USER=postgres
DB_PASSWORD=your_password
```

## Setup

### 1. Create the Database
```bash
psql -U postgres -c "CREATE DATABASE saas_workspace;"
```

### 2. Initialize Schema and Sample Data
```bash
psql -U postgres -d saas_workspace -f database/init.sql
```

That script loads:
- Schema
- Constraints
- Triggers
- Stored procedures
- Indexes
- Sample plans and tenants

### 3. Install Python Dependencies
```bash
pip install -r requirements.txt
```

### 4. Start the Backend
```bash
cd backend
python app.py
```

The API should be available at `http://localhost:5000`.

### 5. Open the Frontend
You can either open the HTML files directly in a browser or serve the folder locally:
```bash
python -m http.server 8000 --directory frontend
```

Then open `http://localhost:8000`.

## How to Use

1. Start on [index.html](frontend/index.html) to register a tenant or select an existing one.
2. The browser stores the active tenant ID in `localStorage`.
3. Use the dashboard as the tenant overview page.
4. Use the dedicated pages for each workflow instead of stacking everything on one screen.

## Backend Endpoints

### Tenants
```text
POST   /tenants
GET    /tenants
GET    /tenants/{id}
PUT    /tenants/{id}
DELETE /tenants/{id}

POST   /tenants/{id}/users
GET    /tenants/{id}/users
GET    /tenants/{id}/users/{user_id}
DELETE /tenants/{id}/users/{user_id}
```

### Workspaces and Deployments
```text
POST   /workspaces
GET    /workspaces?tenant_id=X
GET    /workspaces/{id}?tenant_id=X
PUT    /workspaces/{id}?tenant_id=X
DELETE /workspaces/{id}?tenant_id=X

POST   /workspaces/{id}/deployments?tenant_id=X
GET    /workspaces/{id}/deployments?tenant_id=X
PUT    /workspaces/{id}/deployments/{dep_id}?tenant_id=X
DELETE /workspaces/{id}/deployments/{dep_id}?tenant_id=X
```

### Usage
```text
POST   /usage
GET    /usage?tenant_id=X
GET    /usage/summary?tenant_id=X&start_date=...&end_date=...
```

### Invoices
```text
POST   /invoices/generate
GET    /invoices?tenant_id=X
GET    /invoices/{id}?tenant_id=X
PUT    /invoices/{id}?tenant_id=X
GET    /invoices/plans
GET    /invoices/plans/{id}
```

## Database Notes

The model is tenant-scoped. Core tables include:
- `plans`
- `tenants`
- `users`
- `workspaces`
- `deployments`
- `resource_usage`
- `invoices`
- `audit_logs`

Important rules:
- All tenant data is filtered by `tenant_id`
- Invoice generation uses the PostgreSQL stored procedure `generate_invoice(...)`
- Audit logging is handled with triggers
- Resource usage is validated at the database level

## Testing

### API Smoke Tests
```bash
curl -X POST http://localhost:5000/tenants \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Corp","domain":"testcorp.com","plan_id":2}'

curl -X POST http://localhost:5000/invoices/generate \
  -H "Content-Type: application/json" \
  -d '{"tenant_id":1,"period_start":"2026-04-01","period_end":"2026-04-30"}'
```

### Database Checks
```bash
psql -U postgres -d saas_workspace

SELECT COUNT(*) FROM plans;
SELECT COUNT(*) FROM tenants;
SELECT * FROM generate_invoice(1, '2026-04-01', '2026-04-30', 'system');
SELECT * FROM audit_logs WHERE tenant_id = 1 ORDER BY created_at DESC;
```

## Project Status

The app is currently set up as a working local simulation with:
- A functioning Flask API
- A PostgreSQL schema with constraints, triggers, procedures, and indexes
- A split frontend with dedicated pages
- Tenant cleanup and usage/billing workflows

## Notes

- The frontend no longer depends on a single overloaded dashboard.
- The current design keeps the dashboard as the tenant overview and uses separate pages for the heavier workflows.
- If you see generated `.pyc` files locally, they are safe to ignore.

## Support

If something fails:
1. Check the Flask terminal output
2. Verify PostgreSQL is running
3. Confirm `.env` credentials match your database
4. Open the browser console for frontend errors

