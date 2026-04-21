"""Tenant routes for registration, listing, and management."""

from flask import Blueprint, request, jsonify

import queries

tenant_bp = Blueprint("tenant", __name__, url_prefix="/tenants")


@tenant_bp.route("", methods=["POST"])
def create_tenant():
    """Register a new tenant.

    Request body:
        {
            "name": "Acme Corp",
            "domain": "acme.com",
            "plan_id": 1
        }
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400

    name = data.get("name")
    domain = data.get("domain")
    plan_id = data.get("plan_id")

    if not all([name, domain, plan_id]):
        return jsonify({"error": "name, domain, and plan_id are required"}), 400

    try:
        tenant = queries.create_tenant(name, domain, plan_id)
        return jsonify(tenant), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@tenant_bp.route("", methods=["GET"])
def list_tenants():
    """List all tenants."""
    try:
        tenants = queries.get_all_tenants()
        return jsonify(tenants), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@tenant_bp.route("/<int:tenant_id>", methods=["GET"])
def get_tenant(tenant_id):
    """Get a tenant by ID."""
    try:
        tenant = queries.get_tenant_by_id(tenant_id)
        if tenant:
            return jsonify(tenant), 200
        return jsonify({"error": "Tenant not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@tenant_bp.route("/<int:tenant_id>", methods=["PUT"])
def update_tenant(tenant_id):
    """Update a tenant.

    Request body (all optional):
        {
            "name": "New Name",
            "domain": "newdomain.com",
            "plan_id": 2
        }
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400

    try:
        tenant = queries.update_tenant(
            tenant_id,
            name=data.get("name"),
            domain=data.get("domain"),
            plan_id=data.get("plan_id")
        )
        if tenant:
            return jsonify(tenant), 200
        return jsonify({"error": "Tenant not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@tenant_bp.route("/<int:tenant_id>", methods=["DELETE"])
def delete_tenant(tenant_id):
    """Delete a tenant."""
    try:
        if queries.delete_tenant(tenant_id):
            return jsonify({"message": "Tenant deleted"}), 200
        return jsonify({"error": "Tenant not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# -----------------------------------------------------------------------------
# Tenant Users (Nested resource)
# -----------------------------------------------------------------------------

@tenant_bp.route("/<int:tenant_id>/users", methods=["POST"])
def create_user(tenant_id):
    """Create a user for a tenant.

    Request body:
        {
            "email": "user@example.com",
            "full_name": "John Doe",
            "role": "member"  # optional, defaults to "member"
        }
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400

    email = data.get("email")
    full_name = data.get("full_name")
    role = data.get("role", "member")

    if not all([email, full_name]):
        return jsonify({"error": "email and full_name are required"}), 400

    try:
        user = queries.create_user(tenant_id, email, full_name, role)
        return jsonify(user), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@tenant_bp.route("/<int:tenant_id>/users", methods=["GET"])
def list_users(tenant_id):
    """List all users for a tenant."""
    try:
        users = queries.get_users_by_tenant(tenant_id)
        return jsonify(users), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@tenant_bp.route("/<int:tenant_id>/users/<int:user_id>", methods=["GET"])
def get_user(tenant_id, user_id):
    """Get a user by ID (scoped to tenant)."""
    try:
        user = queries.get_user_by_id(tenant_id, user_id)
        if user:
            return jsonify(user), 200
        return jsonify({"error": "User not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@tenant_bp.route("/<int:tenant_id>/users/<int:user_id>", methods=["DELETE"])
def delete_user(tenant_id, user_id):
    """Delete a user (scoped to tenant)."""
    try:
        if queries.delete_user(tenant_id, user_id):
            return jsonify({"message": "User deleted"}), 200
        return jsonify({"error": "User not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500
