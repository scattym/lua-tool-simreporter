from atlib import *
import time
import sys
import zlib


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


def deflate(filename, outfile=None):
    f = open(filename)
    data = f.read()
    f.close()

    compress = zlib.compressobj(
        0,                # level: 0-9
        zlib.DEFLATED,        # method: must be DEFLATED
        8,      # window size in bits:
                              #   -15..-8: negate, suppress header
                              #   8..15: normal
                              #   16..30: subtract 16, gzip header
        2,   # mem level: 1..8/9
        0                    # strategy:
                              #   0 = Z_DEFAULT_STRATEGY
                              #   1 = Z_FILTERED
                              #   2 = Z_HUFFMAN_ONLY
                              #   3 = Z_RLE
                              #   4 = Z_FIXED
    )
    deflated = compress.compress(data)
    deflated += compress.flush()

    if outfile is not None:
        f = open(outfile, 'w')
        f.write(deflated)
        f.close()

    return deflated


#deflate("network.lua", "test.zip")

try:
    get_response(module)
    change_dir(module, "c:/")

    mkdir(module, "testdir")
    change_dir(module, "c:/testdir")
    ls(module)
    delete_file(module, "test.zip")
    for file in ["ioapi.c", "iowin32.c", "miniunz.c",
                 "minizip.c", "mztools.c", "unzip.c", "zip.c"]:
        delete_file(module, file)

    delete_file(module, "*.c")

    with open("test.zip", 'r') as content_file:
        content = content_file.read()
        put_file(module, "testdir/test.zip", content)

    change_dir(module, "c:/")
    files = [
        "unzip.lua",
    ]
    compile_files = []
    stop_script(module)
    counter = 0
    while(script_is_running(module)):
        print "Script still running"
        counter += 1
        if counter > 30:
            print "Script not stopping, resetting module."
            sys.exit(1)

    for file in files:  # os.listdir("."):
        if os.path.isfile(file):
            if "lua" in file:
                if file_is_newer_than(file, "lastupload/" + file):
                    print "Putting file " + file
                    with open(file, 'r') as content_file:
                        content = content_file.read()
                        put_file(module, file, content)
                        # delete_file(module, file)
                    touch("lastupload/" + file)
                    compile_files.append(file)
                else:
                    print "File %s is not newer than last uploaded version" % (
                        file
                    )

    for file in compile_files:  # os.listdir("."):
        compile_file(module, file)

    for file in files:  # os.listdir("."):
        delete_file(module, file)

    # compile_file(module, "reporter.lua")
    ls(module)

    run_script(module, "unzip.out")

    read_all(module)

finally:
    module.close()
