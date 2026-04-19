import os
from flask import Flask, request, jsonify

app = Flask(__name__)

WELCOME_MSG = os.getenv("WELCOME_MSG", "Welcome to the app")
LOG_FILE_PATH = "/app/logs/app.log"

os.makedirs(os.path.dirname(LOG_FILE_PATH), exist_ok=True)

@app.route("/", methods=["GET"])
def index():
    return WELCOME_MSG


@app.route("/status", methods=["GET"])
def status():
    return jsonify({"status": "ok"})


@app.route("/log", methods=["POST"])
def write_log():
    data = request.json
    if not data or "message" not in data:
        return jsonify({"error": "Missing 'message' field"}), 400

    log_entry = data["message"]

    with open(LOG_FILE_PATH, "a") as f:
        f.write(log_entry + "\n")

    return jsonify({"result": "log saved"}), 201


@app.route("/logs", methods=["GET"])
def read_logs():
    if not os.path.exists(LOG_FILE_PATH):
        return "No logs yet."

    with open(LOG_FILE_PATH, "r") as f:
        content = f.read()
    return content


if __name__ == "__main__":
    port = int(os.getenv("APP_PORT", 8080))
    app.run(host="0.0.0.0", port=port)
