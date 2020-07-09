#!/usr/bin/env python

#simplePingExample.py
from brping import PingDevice, definitions, pingmessage
import time
import argparse

from builtins import input

##Parse Command line options
############################

parser = argparse.ArgumentParser(description="Ping python library example.")
parser.add_argument('--device', action="store", required=False, type=str, help="Ping device port. E.g: /dev/ttyUSB0")
parser.add_argument('--baudrate', action="store", type=int, default=115200, help="Ping device baudrate. E.g: 115200")
parser.add_argument('--udp', action="store", required=False, type=str, help="Ping UDP server. E.g: 192.168.2.2:9090")
args = parser.parse_args()
if args.device is None and args.udp is None:
    parser.print_help()
    exit(1)

# Make a new Ping
bp = PingDevice()
if args.device is not None:
    bp.connect_serial(args.device, args.baudrate)
elif args.udp is not None:
    (host, port) = args.udp.split(':')
    bp.connect_udp(host, int(port))

if bp.initialize() is False:
    print("Failed to initialize beamplot!")
    exit(1)

m = pingmessage.PingMessage(definitions.BEAMPLOT_TAKE_SAMPLES)
m.nsamples = 5000
m.pack_msg_data()
bp.write(m.msg_data);

print(bp.wait_message([definitions.BEAMPLOT_RX_DATA], 20))

