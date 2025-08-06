
from flask import Flask, redirect, abort, request
import yaml
import os

app = Flask(__name__)

CONFIG_PATH = os.path.join(os.path.dirname(__file__), 'redirects.yml')

def load_redirects():
    try:
        with open(CONFIG_PATH, 'r') as f:
            data = yaml.safe_load(f)
        if not isinstance(data, dict):
            raise ValueError("YAML root must be a dictionary.")
        # Validate structure: each hole must be a dict with qr keys
        for hole, qrs in data.items():
            if not isinstance(qrs, dict):
                raise ValueError(f"Entry for {hole} must be a dictionary of QR codes.")
            for qr, url in qrs.items():
                if not isinstance(url, str):
                    raise ValueError(f"URL for {hole}/{qr} must be a string.")
        return data
    except Exception as e:
        # Store error for use in route
        app.config['YAML_ERROR'] = str(e)
        return None

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def catch_all(path):
    redirects = load_redirects()
    if redirects is None:
        error = app.config.get('YAML_ERROR', 'Unknown YAML error')
        return f"YAML config error: {error}", 500
    # Build possible key from path, e.g. 'hole1/qr1' -> ['hole1', 'qr1']
    parts = path.split('/')
    if len(parts) == 2:
        hole, qr = parts
        url = redirects.get(hole, {}).get(qr)
        if url:
            return redirect(url)
    return abort(404)

@app.route('/')
def index():
    return "Disc Golf QR Redirector is running."

if __name__ == '__main__':
    app.run(debug=True)
