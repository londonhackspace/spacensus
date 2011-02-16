#!/usr/bin/env python

import BaseHTTPServer, serial, ConfigParser, sys, re, time, urlparse, urllib

config = ConfigParser.ConfigParser()
config.read((
    'spacensus.conf',
    sys.path[0] + '/spacensus.conf',
    '/etc/spacensus.conf'
))

serialPort = config.get('spacensus', 'serialport')
port = serial.Serial(serialPort, 9600, timeout=1)

class Handler(BaseHTTPServer.BaseHTTPRequestHandler):

    # Disable logging DNS lookups
    def address_string(self):
        return str(self.client_address[0])

    def do_GET(self):
        url = urlparse.urlparse(self.path)
        path = url.path
        path = path.lstrip('/')
        message = urllib.unquote(path)
        message = message[:1]
    
        port.write(message);
        time.sleep(0.5)
        line = port.readline();
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(line)
        self.wfile.write('\n')
        self.wfile.flush()

PORT = config.getint('spacensus', 'tcpport')
httpd = BaseHTTPServer.HTTPServer(("", PORT), Handler)
httpd.serve_forever()
