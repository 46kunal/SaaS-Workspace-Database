"""Billing routes for invoice generation and management."""

from flask import Blueprint, request, jsonify

import queries

billing_bp = Blueprint("billing", __name__, url_prefix="/invoices")


@billing_bp.route("", methods=["GET"])
def list_invoices():
    """List invoices for a tenant.

    Query params:
        tenant_id (required): Tenant ID
    """
    tenant_id = request.args.get("tenant_id", type=int)
    if not tenant_id:
        return jsonify({"error": "tenant_id query parameter required"}), 400

    try:
        invoices = queries.get_invoices_by_tenant(tenant_id)
        return jsonify(invoices), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@billing_bp.route("/<int:invoice_id>", methods=["GET"])
def get_invoice(invoice_id):
    """Get an invoice by ID.

    Query params:
        tenant_id (required): Tenant scope
    """
    tenant_id = request.args.get("tenant_id", type=int)
    if not tenant_id:
        return jsonify({"error": "tenant_id query parameter required"}), 400

    try:
        invoice = queries.get_invoice_by_id(tenant_id, invoice_id)
        if invoice:
            return jsonify(invoice), 200
        return jsonify({"error": "Invoice not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@billing_bp.route("/generate", methods=["POST"])
def generate_invoice():
    """Generate an invoice for a tenant.

    Calls Om's generate_invoice stored procedure.

    Request body:
        {
            "tenant_id": 1,
            "period_start": "2024-01-01",
            "period_end": "2024-01-31"
        }
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400

    tenant_id = data.get("tenant_id")
    period_start = data.get("period_start")
    period_end = data.get("period_end")

    if not all([tenant_id, period_start, period_end]):
        return jsonify({"error": "tenant_id, period_start, and period_end are required"}), 400

    try:
        invoice = queries.generate_invoice(tenant_id, period_start, period_end)
        if invoice:
            return jsonify(invoice), 201
        return jsonify({"error": "Failed to generate invoice"}), 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@billing_bp.route("/<int:invoice_id>", methods=["PUT"])
def update_invoice_status(invoice_id):
    """Update an invoice's status.

    Query params:
        tenant_id (required): Tenant scope

    Request body:
        {
            "status": "paid"  # pending, paid, overdue
        }
    """
    tenant_id = request.args.get("tenant_id", type=int)
    if not tenant_id:
        return jsonify({"error": "tenant_id query parameter required"}), 400

    data = request.get_json()
    if not data or not data.get("status"):
        return jsonify({"error": "status is required in request body"}), 400

    status = data["status"]
    if status not in ("pending", "paid", "overdue"):
        return jsonify({"error": "status must be one of: pending, paid, overdue"}), 400

    try:
        invoice = queries.update_invoice_status(tenant_id, invoice_id, status)
        if invoice:
            return jsonify(invoice), 200
        return jsonify({"error": "Invoice not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# -----------------------------------------------------------------------------
# Plans (Accessible without tenant scope)
# -----------------------------------------------------------------------------

@billing_bp.route("/plans", methods=["GET"])
def list_plans():
    """List all available plans."""
    try:
        plans = queries.get_all_plans()
        return jsonify(plans), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@billing_bp.route("/plans/<int:plan_id>", methods=["GET"])
def get_plan(plan_id):
    """Get a plan by ID."""
    try:
        plan = queries.get_plan_by_id(plan_id)
        if plan:
            return jsonify(plan), 200
        return jsonify({"error": "Plan not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500
