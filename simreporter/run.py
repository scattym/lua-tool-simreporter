from atlib import *
import time
from __builtin__ import file


#module = serial.Serial("/dev/cu.usbserial-A105NJ7M",  115200, timeout=5)
module = serial.serial_for_url("rfc2217://10.1.1.5:9990", 115200, timeout=5)
#module = serial.Serial("/dev/ttyUSB0",  115200, timeout=5)

import os


def touch(fname, times=None):
    with open(fname, 'a'):
        os.utime(fname, times)


import os.path


def file_is_newer_than(file1, file2):
    if os.path.isfile(file1) and os.path.isfile(file2):
        return os.path.getctime(file1) > os.path.getctime(file2)
    return True


try:
    get_response(module)
    change_dir(module, "c:/")

    mkdir(module, "testdir")
    change_dir(module, "c:/testdir")
    with open("test.zip", 'r') as content_file:
        content = content_file.read()
        put_file(module, "testdir/test.zip", content)

finally:
    module.close()
