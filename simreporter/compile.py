#!/usr/bin/env python

from atlib import *
import time
import os
import os.path
import argparse

# module = serial.Serial("/dev/cu.usbserial-A105NJ7M",  115200, timeout=5)
serial_port = serial.serial_for_url("rfc2217://10.1.1.5:9991", 115200, timeout=5)
# module = serial.Serial("/dev/ttyUSB0",  115200, timeout=5)

VERSION = "201709141"

files = [
#    "aes.lua",
    "at_abs.lua",
    "at_commands.lua",
    "basic_threads.lua",
    "canary.lua",
    "config.lua",
    "device.lua",
    "encapsulation.lua",
    "firmware.lua",
    "json.lua",
    "logging.lua",
    "network_setup.lua",
    "nmea_getinfo.lua",
    "reporter.lua",
    "system.lua",
    "tcp_client.lua",
    "util.lua",
    "unzip.lua",
]


def transfer_and_build_files(directory, send_loader):
    try:
        change_dir(serial_port, "c:/libs/" + directory)
    
        for filename in files:  # os.listdir("."):
            compile_file(serial_port, "c:/libs/" + directory + "/" + filename)
    
        for filename in files:  # os.listdir("."):
            delete_file(serial_port, filename)
    
        change_dir(serial_port, "c:/")
        if send_loader:
            with open("loader.lua", 'r') as content_file:
                content = content_file.read()
                put_file(serial_port, "c:/loader.lua", content)
            compile_file(serial_port, "loader.lua")
            delete_file(serial_port, "autorun.out")
            delete_file(serial_port, "loader.lua")
            copy_file(serial_port, "loader.out", "autorun.out")

        set_autorun(serial_port, True)
        run_script(serial_port, "loader.out")
        read_all(serial_port)
    
    finally:
        serial_port.close()

if __name__ == '__main__':

    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        '-f',
        '--force-all-files',
        help="Force the transfer of all files. Overrides lastupload logic.",
        default=False,
        action="store_true"
    )
    parser.add_argument(
        '-l',
        '--loader',
        help="Also update the loader.",
        default=False,
        action="store_true"
    )
    parser.add_argument(
        '-n',
        '--no-initial-reset',
        help="The target directory in libs. Defaults to base.",
        default=False,
        action="store_true"
    )
    parser.add_argument(
        '-d',
        '--directory',
        help="The target directory in libs. Defaults to base.",
        default="base"
    )

    parser.add_argument(
        '-t',
        '--transfer-file',
        help="Force transfer of this file only.",
        default=None,
    )
    parser.add_argument(
        '-z',
        '--zip-files',
        help="Create zip file and don't upload scripts to device.",
        default=False,
        action="store_true"
    )

    args = parser.parse_args()

    transfer_and_build_files(args.directory, args.loader)
