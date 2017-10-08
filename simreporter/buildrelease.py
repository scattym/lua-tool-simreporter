#!/usr/bin/env python

from atlib import *
import time
import os
import os.path
import argparse
import ConfigParser

config = ConfigParser.RawConfigParser()
config.read('release.cfg')

# module = serial.Serial("/dev/cu.usbserial-A105NJ7M",  115200, timeout=5)
serial_port = serial.serial_for_url("rfc2217://10.1.1.5:9991", 115200, timeout=5)
# module = serial.Serial("/dev/ttyUSB0",  115200, timeout=5)

VERSION = "201709141"
files = config.get('release', 'files').split(",")


def zip_files():
    cmd = "~/git/zlib/contrib/minizip/minizip %s.zip %s" % (VERSION, " ".join(files))
    print(cmd)
    result = os.system(cmd)
    print("Result is %s" % result)


def touch(fname, times=None):
    with open(fname, 'a'):
        os.utime(fname, times)


def file_is_newer_than(file1, file2):
    if os.path.isfile(file1) and os.path.isfile(file2):
        return os.path.getctime(file1) > os.path.getctime(file2)
    return True


def transfer_and_build_files(directory, initial_reset, force_all_files, send_loader, only_file):
    try:
        set_autorun(serial_port, False)
        if initial_reset:
            reset(serial_port)
            response = get_response(serial_port, 2)
            while "START" not in response:
                print("Waiting for module to start.")
                response = get_response(serial_port, 2)
            time.sleep(13)
            print("Module now ready.")
        else:
            print("Not resetting. Be sure the script is not running.")

        change_dir(serial_port, "c:/")
        mkdir(serial_port, "libs")
        change_dir(serial_port, "libs")
        mkdir(serial_port, directory)
        change_dir(serial_port, directory)

        for filename in files:  # os.listdir("."):
            print("Filename is %s" %filename)
            if "lua" in filename:
                print "Putting file " + filename
                with open(filename, 'r') as content_file:
                    content = content_file.read()
                    put_file(serial_port, "c:/libs/" + directory + "/" + filename, content)
                    # delete_file(module, file)

        # for file in files:  # os.listdir("."):
        #     compiled = file.replace(".lua", ".out")
        #     delete_file(module, compiled)
        time.sleep(2)
        for filename in files:  # os.listdir("."):
            compile_file(serial_port, "c:/libs/" + directory + "/" + filename)

        for filename in files:  # os.listdir("."):
            delete_file(serial_port, filename)

        for filename in files:
            built_file = filename.replace(".lua", ".out")
            data = get_file(serial_port, "c:/libs/%s/%s" % (directory, built_file))
            f = open("/tmp/%s" % os.path.basename(built_file), 'w')
            f.write(data)
            f.close()

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
        default="builder"
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

    if args.zip_files:
        zip_files()
    else:
        transfer_and_build_files(args.directory, not args.no_initial_reset, args.force_all_files, args.loader,
                                 args.transfer_file)
