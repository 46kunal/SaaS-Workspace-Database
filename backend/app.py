"""Flask application with multi-tenant SaaS API."""

import os

from flask import Flask, jsonify
from flask_cors import CORS

from db import init_pool, close_pool
from routes import tenant_bp, workspace_bp, usage_bp, billing_bp

app = Flask(__name__)

# Enable CORS for frontend
CORS(app, resources={r"/*": {"origins": "*"}})

# Register blueprints
app.register_blueprint(tenant_bp)
app.register_blueprint(workspace_bp)
app.register_blueprint(usage_bp)
app.register_blueprint(billing_bp)


@app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint."""
    return jsonify({"status": "healthy"}), 200


@app.route("/test", methods=["GET"])
def test_route():
    """Test endpoint."""
    return jsonify({"message": "API is working"}), 200


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({"error": "Not found"}), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    return jsonify({"error": "Internal server error"}), 500


@app.before_request
def before_request():
    """Initialize connection pool before first request."""
    init_pool()


@app.teardown_appcontext
def teardown(exception):
    """Clean up on app context teardown."""
    pass


def create_app():
    """Application factory."""
    return app


if __name__ == "__main__":
    host = os.getenv("FLASK_HOST", "0.0.0.0")
    port = int(os.getenv("FLASK_PORT", 5000))
    debug = os.getenv("FLASK_DEBUG", "true").lower() == "true"

    app.run(host=host, port=port, debug=debug)
