from http.server import BaseHTTPRequestHandler, HTTPServer

hostName = "0.0.0.0"
serverPort = 80

class MyServer(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/stress":
            # Симуляція навантаження через обчислення фібоначчівих чисел
            self.simulate_load()

        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()

        if self.path == "/":
            self.wfile.write(bytes("<html><head><title>STEP 4</title>", "utf-8"))
            self.wfile.write(bytes("<style>", "utf-8"))
            self.wfile.write(bytes("body {background-color: black; color: white; height: 100vh; display: flex; justify-content: center; align-items: center; margin: 0; font-family: 'Montserrat', sans-serif;}", "utf-8"))
            self.wfile.write(bytes("</style></head>", "utf-8"))
            self.wfile.write(bytes("<body>", "utf-8"))
            self.wfile.write(bytes("<h1>STEP 4 v3.0</h1>", "utf-8"))
            self.wfile.write(bytes("</body></html>", "utf-8"))
        elif self.path == "/stress":
            self.wfile.write(bytes("<html><head><title>Stress Test</title></head>", "utf-8"))
            self.wfile.write(bytes("<body><h1>Stress Test Page</h1></body></html>", "utf-8"))

    def simulate_load(self):

        def fib(n):
            if n < 2:
                return n
            return fib(n - 1) + fib(n - 2)

        fib(32)

if __name__ == "__main__":
    webServer = HTTPServer((hostName, serverPort), MyServer)
    print("Server started http://%s:%s" % (hostName, serverPort))

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    print("Server stopped.")
