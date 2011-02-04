#!/usr/bin/env python

import BaseHTTPServer, serial, ConfigParser, sys, re, time

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
        serial.send('S');
        time.sleep(0.5)
        line = ser.readline();
        m = re.search('[KA]{1}[ION]{1}[XL]{1}([0-9]+)', line)
        people = m.group(1);
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write('people:')
        self.wfile.write(people)
        self.wfile.write('\n')
        self.wfile.flush()

PORT = config.getint('spacensus', 'tcpport')
httpd = BaseHTTPServer.HTTPServer(("", PORT), Handler)
httpd.serve_forever()