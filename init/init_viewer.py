from http.server import SimpleHTTPRequestHandler, HTTPServer
import time

class LogRequestHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()

            # Inline HTML content with styles and JavaScript
            html_content = """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Initialization Progress</title>
                <style>
                    body { font-family: monospace; white-space: pre; background-color: #f0f0f0; }
                    #log { margin: 20px; padding: 20px; border: 1px solid #ccc; background: #fff; height: 400px; overflow-y: scroll; }
                </style>
                <script>
                    function fetchLog() {
                        fetch('/log')
                            .then(response => response.text())
                            .then(data => {
                                var logDiv = document.getElementById('log');
                                logDiv.innerText = data;
                                logDiv.scrollTop = logDiv.scrollHeight; // Scroll to bottom
                                setTimeout(fetchLog, 2000); // Fetch every 2 seconds
                            });
                    }
                    window.onload = fetchLog;
                </script>
            </head>
            <body>
                <h1>Initialization Progress</h1>
                <div id="log">Loading...</div>
            </body>
            </html>
            """
            self.wfile.write(html_content.encode('utf-8'))

        elif self.path == '/log':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            with open('/opt/larynx-init/init_log.txt', 'r') as file:
                log_content = file.read()
                self.wfile.write(log_content.encode('utf-8'))
        else:
            self.send_error(404, "File Not Found")

def run(server_class=HTTPServer, handler_class=LogRequestHandler, port=8087):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f"Starting HTTP server on port {port}...")
    httpd.serve_forever()

if __name__ == '__main__':
    run()
