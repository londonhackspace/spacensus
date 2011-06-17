#!/usr/bin/env python

import threading, logging, BaseHTTPServer, serial, ConfigParser, sys, re, time, urlparse, urllib

logger = logging.getLogger("spacensus")
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
formatter = logging.Formatter("%(asctime)s - %(message)s")
ch.setFormatter(formatter)
logger.addHandler(ch)

config = ConfigParser.ConfigParser()
config.read((
    'spacensus.conf',
    sys.path[0] + '/spacensus.conf',
    '/etc/spacensus.conf'
))

serialPort = config.get('spacensus', 'serialport')
port = serial.Serial(serialPort, 9600, timeout=1)

line = ""

class SerialReader(threading.Thread):

    def run(self):
        while 1:
            line = port.readline()
            logger.debug("spacensus event: %s", line)

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
        logger.info("sending command: %s", message)
        
        port.write(message)
        time.sleep(1.0)
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
