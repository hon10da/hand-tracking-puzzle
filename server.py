# Local-only Puzzle Cam server and recording storage. No third-party packages.
import http.server
import json
import os
import sys
from pathlib import Path
import secrets
import webbrowser
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parent
MAX_BYTES = 300 * 1024 * 1024

class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      '.mjs': 'text/javascript', '.wasm': 'application/wasm', '.task': 'application/octet-stream'}
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)
    def reply(self, status, data):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(body)
    def do_POST(self):
        expected = f'http://localhost:{self.server.server_port}'
        if (self.path != '/api/recordings' or self.headers.get('Origin') != expected
                or self.headers.get('X-PuzzleCam') != 'recording-v1'):
            self.close_connection = True
            self.reply(403, {'saved': False, 'error': 'Local app requests only'})
            return
        try:
            size = int(self.headers.get('Content-Length', '-1'))
        except ValueError:
            size = -1
        if not 0 < size <= MAX_BYTES:
            self.close_connection = True
            self.reply(413, {'saved': False, 'error': 'Empty video or video exceeds 300 MB'})
            return
        tmp = None
        try:
            folder = ROOT / 'recordings'
            folder.mkdir(exist_ok=True)
            name = 'puzzle-' + datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S-') + secrets.token_hex(6) + '.webm'
            target = folder / name
            tmp = target.with_suffix('.part')
            self.connection.settimeout(120)
            remaining = size
            with tmp.open('xb') as out:
                while remaining:
                    block = self.rfile.read(min(65536, remaining))
                    if not block:
                        raise IOError('Incomplete upload')
                    out.write(block)
                    remaining -= len(block)
                out.flush()
                os.fsync(out.fileno())
            tmp.rename(target)
            self.reply(201, {'saved': True, 'path': 'recordings/' + name})
        except Exception:
            if tmp is not None:
                tmp.unlink(missing_ok=True)
            self.reply(500, {'saved': False, 'error': 'Could not write video. Check folder permissions and disk space.'})
    def do_GET(self):
        if self.path.startswith('/recordings/'):
            self.send_error(403, 'Open saved recordings in the project folder')
            return
        super().do_GET()

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    try:
        with http.server.ThreadingHTTPServer(('localhost', port), Handler) as server:
            print(f'Puzzle Cam: http://localhost:{port}/ . Keep this window open. Videos: recordings/', flush=True)
            webbrowser.open(f'http://localhost:{port}/')
            server.serve_forever()
    except OSError as error:
        input(f'Cannot start local server: {error}. Close the old server window and retry. Press Enter.')
