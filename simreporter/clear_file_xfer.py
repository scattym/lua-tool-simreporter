#!/usr/bin/env python
from atlib import *
import time
import serial
import ConfigParser

serial_port = open_config_port()

try:
    while "OK" not in get_response(serial_port):
        serial_port.write("at\r\n" * 100)

finally:
    serial_port.close()
