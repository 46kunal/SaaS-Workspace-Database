"""Workspace routes for CRUD operations."""

from flask import Blueprint, request, jsonify

import queries

workspace_bp = Blueprint("workspace", __name__, url_prefix="/workspaces")


@workspace_bp.route("", methods=["POST"])
def create_workspace():
    """Create a new workspace.

    Request body:
        {
            "tenant_id": 1,
            "name": "Production",
            "created_by": 1  # user_id
        }
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400

    tenant_id = data.get("tenant_id")
    name = data.get("name")
    created_by = data.get("created_by")

    if not all([tenant_id, name]):
        return jsonify({"error": "tenant_id and name are required"}), 400

    try:
        workspace = queries.create_workspace(tenant_id, name, created_by)
        return jsonify(workspace), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@workspace_bp.route("", methods=["GET"])
def list_workspaces():
    """List workspaces for a tenant.

    Query params:
        tenant_id (required): Filter by tenant
    """
    tenant_id = request.args.get("tenant_id", type=int)
    if not tenant_id:
        return jsonify({"error": "tenant_id query parameter required"}), 400

    try:
        workspaces = queries.get_workspaces_by_tenant(tenant_id)
        return jsonify(workspaces), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@workspace_bp.route("/<int:workspace_id>", methods=["GET"])
def get_workspace(workspace_id):
    """Get a workspace by ID.

    Query params:
        tenant_id (required): Tenant scope for multi-tenancy
    """
    tenant_id = request.args.get("tenant_id", type=int)
    if not tenant_id:
        return jsonify({"error": "tenant_id query parameter required"}), 400

    try:
        workspace = queries.get_workspace_by_id(tenant_id, workspace_id)
        if workspace:
            return jsonify(workspace), 200
        return jsonify({"error": "Workspace not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@workspace_bp.route("/<int:workspace_id>", methods=["PUT"])
def update_workspace(workspace_id):
    """Update a workspace.

    Query params:
        tenant_id (required): Tenant scope for multi-tenancy

    Request body:
        {
            "name": "New Name"
        }
    """
    tenant_id = request.args.get("tenant_id", type=int)
    if not tenant_id:
        return jsonify({"error": "tenant_id query parameter required"}), 400

    data = request.get_json()
    if not data or not data.get("name"):
        return jsonify({"error": "name is required in request body"}), 400

    try:
        workspace = queries.update_workspace(tenant_id, workspace_id, data["name"])
        if workspace:
            return jsonify(workspace), 200
        return jsonify({"error": "Workspace not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@workspace_bp.route("/<int:workspace_id>", methods=["DELETE"])
def delete_workspace(workspace_id):
    """Delete a workspace.

    Query params:
        tenant_id (required): Tenant scope for multi-tenancy
    """
    tenant_id = request.args.get("tenant_id", type=int)
    if not tenant_id:
        return jsonify({"error": "tenant_id query parameter required"}), 400

    try:
        if queries.delete_workspace(tenant_id, workspace_id):
            return jsonify({"message": "Workspace deleted"}), 200
        return jsonify({"error": "Workspace not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# -----------------------------------------------------------------------------
# Deployments (Nested under workspace)
# -----------------------------------------------------------------------------

@workspace_bp.route("/<int:workspace_id>/deployments", methods=["POST"])
def create_deployment(workspace_id):
    """Create a deployment in a workspace.

    Query params:
        tenant_id (required): Tenant scope

    Request body:
        {
            "name": "my-app",
            "version": "1.0.0",
            "status": "running"  # optional, defaults to "running"
        }
    """
    tenant_id = request.args.get("tenant_id", type=int)
    if not tenant_id:
        return jsonify({"error": "tenant_id query parameter required"}), 400

    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400

    name = data.get("name")
    version = data.get("version")
    status = data.get("status", "running")

    if not all([name, version]):
        return jsonify({"error": "name and version are required"}), 400

    try:
        deployment = queries.create_deployment(tenant_id, workspace_id, name, version, status)
        return jsonify(deployment), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@workspace_bp.route("/<int:workspace_id>/deployments", methods=["GET"])
def list_deployments(workspace_id):
    """List deployments in a workspace.

    Query params:
        tenant_id (required): Tenant scope
    """
    tenant_id = request.args.get("tenant_id", type=int)
    if not tenant_id:
        return jsonify({"error": "tenant_id query parameter required"}), 400

    try:
        deployments = queries.get_deployments_by_workspace(tenant_id, workspace_id)
        return jsonify(deployments), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@workspace_bp.route("/<int:workspace_id>/deployments/<int:deployment_id>", methods=["PUT"])
def update_deployment(workspace_id, deployment_id):
    """Update a deployment's status.

    Query params:
        tenant_id (required): Tenant scope

    Request body:
        {
            "status": "stopped"
        }
    """
    tenant_id = request.args.get("tenant_id", type=int)
    if not tenant_id:
        return jsonify({"error": "tenant_id query parameter required"}), 400

    data = request.get_json()
    if not data or not data.get("status"):
        return jsonify({"error": "status is required in request body"}), 400

    try:
        deployment = queries.update_deployment_status(tenant_id, deployment_id, data["status"])
        if deployment:
            return jsonify(deployment), 200
        return jsonify({"error": "Deployment not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@workspace_bp.route("/<int:workspace_id>/deployments/<int:deployment_id>", methods=["DELETE"])
def delete_deployment(workspace_id, deployment_id):
    """Delete a deployment.

    Query params:
        tenant_id (required): Tenant scope
    """
    tenant_id = request.args.get("tenant_id", type=int)
    if not tenant_id:
        return jsonify({"error": "tenant_id query parameter required"}), 400

    try:
        if queries.delete_deployment(tenant_id, deployment_id):
            return jsonify({"message": "Deployment deleted"}), 200
        return jsonify({"error": "Deployment not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500
