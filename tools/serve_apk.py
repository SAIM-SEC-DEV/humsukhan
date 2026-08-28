from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

apk = Path('/home/ubuntu/projects/humsukhan/build/app/outputs/flutter-apk/app-release.apk')
root = apk.parent

class ApkHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(root), **kwargs)

    def end_headers(self):
        self.send_header('Content-Disposition', 'attachment; filename="HumSukhan.apk"')
        super().end_headers()

    def log_message(self, format, *args):
        print(format % args, flush=True)

server = ThreadingHTTPServer(('0.0.0.0', 8765), ApkHandler)
print(f'Serving {apk} on port 8765', flush=True)
server.serve_forever()
