import socket
import subprocess
import sys
import time
import webbrowser
from pathlib import Path


HOST = "127.0.0.1"
PORT = 8501
URL = f"http://localhost:{PORT}"
BASE_DIR = Path(__file__).resolve().parent


def wait_until_ready(host, port, timeout_seconds=30):
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        try:
            with socket.create_connection((host, port), timeout=1):
                return True
        except OSError:
            time.sleep(0.5)
    return False


def main():
    cmd = [
        sys.executable,
        "-m",
        "streamlit",
        "run",
        str(BASE_DIR / "app.py"),
        "--server.headless=false",
        f"--server.port={PORT}",
    ]
    process = subprocess.Popen(cmd, cwd=BASE_DIR)
    if wait_until_ready(HOST, PORT):
        webbrowser.open(URL)
        print(f"Streamlit is running at {URL}")
    else:
        print(f"Streamlit started, but {URL} was not reachable within 30 seconds.")
    process.wait()


if __name__ == "__main__":
    main()
