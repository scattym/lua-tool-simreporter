#!/usr/bin/env python

import ConfigParser
from atlib import *


config = ConfigParser.RawConfigParser()
config.read('release.cfg')

VERSION = "201709141"
files = config.get('release', 'files').split(",")

serial_port = open_config_port()
try:


    change_dir(serial_port, "c:/")
    change_dir(serial_port, "libs")
    files = ls(serial_port)
    for file in files.replace('\r', '').split("\n"):
        if file not in ["base", "AT+FSLS", ""] and "SUBDIRECT" not in file:
            change_dir(serial_port, file)
            delete_file(serial_port, "*.*")
            change_dir(serial_port, "..")
            rmdir(serial_port, file)

    change_dir(serial_port, "c:/")
    delete_file(serial_port, "qurantined.txt")


finally:
    serial_port.close()
