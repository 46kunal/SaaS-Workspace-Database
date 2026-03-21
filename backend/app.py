"""Minimal Flask app scaffold."""

from flask import Flask


app = Flask(__name__)


@app.route("/test", methods=["GET"])
def test_route():
	"""TODO: replace with real logic."""
	return {"message": "test ok"}


# TODO: register blueprints once implemented


if __name__ == "__main__":
	# TODO: configure host/port/env via settings
	app.run(debug=True)
