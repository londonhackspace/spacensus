#!/usr/bin/env python

import threading, logging, BaseHTTPServer, serial, ConfigParser, sys, re, time, urlparse, urllib

logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s %(message)s',
                    filename='/var/log/spacensus/spacensus.log')

config = ConfigParser.ConfigParser()
config.read((
    'spacensus.conf',
    sys.path[0] + '/spacensus.conf',
    '/etc/spacensus.conf'
))

serialPort = config.get('spacensus', 'serialport')
port = serial.Serial(serialPort, 9600, timeout=None)

line = ""

class SerialReader(threading.Thread):

    def run(self):
        global line
        while 1:
            line = port.readline().strip()
            logging.debug("event: %s", line)

class Handler(BaseHTTPServer.BaseHTTPRequestHandler):

    # Disable logging DNS lookups
    def address_string(self):
        return str(self.client_address[0])

    def do_GET(self):
        global line
        url = urlparse.urlparse(self.path)
        path = url.path
        path = path.lstrip('/')
        message = urllib.unquote(path)
        message = message[:1]
        logging.info("sending command: %s", message)
        
        port.write(message)
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(line)
        self.wfile.write('\n')
        self.wfile.flush()

thread = SerialReader()
thread.start()
            
PORT = config.getint('spacensus', 'tcpport')
httpd = BaseHTTPServer.HTTPServer(("", PORT), Handler)
httpd.serve_forever()
