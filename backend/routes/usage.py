"""Usage routes for logging and reporting resource consumption."""

from flask import Blueprint, request, jsonify

import queries

usage_bp = Blueprint("usage", __name__, url_prefix="/usage")


@usage_bp.route("", methods=["POST"])
def record_usage():
    """Record resource usage.

    Request body:
        {
            "tenant_id": 1,
            "workspace_id": 1,
            "api_calls": 150,
            "storage_mb": 25.5,
            "usage_date": "2024-01-15"
        }
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400

    tenant_id = data.get("tenant_id")
    workspace_id = data.get("workspace_id")
    api_calls = data.get("api_calls")
    storage_mb = data.get("storage_mb")
    usage_date = data.get("usage_date")

    if not all([tenant_id, workspace_id, api_calls is not None, storage_mb is not None, usage_date]):
        return jsonify({"error": "tenant_id, workspace_id, api_calls, storage_mb, and usage_date are required"}), 400

    try:
        usage = queries.record_usage(tenant_id, workspace_id, api_calls, storage_mb, usage_date)
        return jsonify(usage), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@usage_bp.route("", methods=["GET"])
def get_usage():
    """Get usage records for a tenant.

    Query params:
        tenant_id (required): Tenant ID
        start_date (optional): Filter from date (YYYY-MM-DD)
        end_date (optional): Filter to date (YYYY-MM-DD)
    """
    tenant_id = request.args.get("tenant_id", type=int)
    if not tenant_id:
        return jsonify({"error": "tenant_id query parameter required"}), 400

    start_date = request.args.get("start_date")
    end_date = request.args.get("end_date")

    try:
        usage_records = queries.get_usage_by_tenant(tenant_id, start_date, end_date)
        return jsonify(usage_records), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@usage_bp.route("/summary", methods=["GET"])
def get_usage_summary():
    """Get aggregated usage summary for a tenant.

    Query params:
        tenant_id (required): Tenant ID
        start_date (required): Period start (YYYY-MM-DD)
        end_date (required): Period end (YYYY-MM-DD)
    """
    tenant_id = request.args.get("tenant_id", type=int)
    start_date = request.args.get("start_date")
    end_date = request.args.get("end_date")

    if not all([tenant_id, start_date, end_date]):
        return jsonify({"error": "tenant_id, start_date, and end_date query parameters required"}), 400

    try:
        summary = queries.get_usage_summary(tenant_id, start_date, end_date)
        return jsonify(summary), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
