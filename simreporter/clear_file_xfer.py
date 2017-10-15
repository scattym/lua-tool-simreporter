#!/usr/bin/env python
from atlib import *
import time
import serial


#module = serial.Serial("/dev/cu.usbserial-A105NJ7M",  115200, timeout=5)
device = serial.serial_for_url("rfc2217://10.1.1.5:9990", 115200, timeout=5)
# module = serial.Serial("/dev/ttyUSB0",  115200, timeout=5)

try:
    while "OK" not in get_response(device):
        device.write("at\r\n" * 100)

finally:
    device.close()
