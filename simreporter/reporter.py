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
    "aes.lua",
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


def zip_files():
    cmd = "~/git/zlib/contrib/minizip/minizip %s.zip %s" % (VERSION,  " ".join(files))
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

        compile_files = []

        for filename in files:  # os.listdir("."):
            if only_file is None or only_file == filename:
                if os.path.isfile(filename):
                    if "lua" in filename:
                        if file_is_newer_than(filename, "lastupload/" + filename) or force_all_files:
                            print "Putting file " + filename
                            with open(filename, 'r') as content_file:
                                content = content_file.read()
                                put_file(serial_port, "c:/libs/" + directory + "/" + filename, content)
                                # delete_file(module, file)
                            touch("lastupload/" + filename)
                            compile_files.append(filename)
                        else:
                            print("File %s is not newer than last uploaded version" % (
                                filename
                            ))
    
        # for file in files:  # os.listdir("."):
        #     compiled = file.replace(".lua", ".out")
        #     delete_file(module, compiled)
        time.sleep(2)
        for filename in compile_files:  # os.listdir("."):
            compile_file(serial_port, "c:/libs/" + directory + "/" + filename)
    
        for filename in compile_files:  # os.listdir("."):
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

        # compile_file(module, "reporter.lua")
        ls(serial_port)
    
        # run_script(module, "reporter.out")
        # stop_script(module)
        # while(script_is_running(module)):
        #    print "Script still running"
        # try:
        #    run_script(module, "nmea_getinfo.out")
        # except ValueError as error:
        #    get_response(module, 2)
        #    get_response(module, 2)
        #    run_script(module, "nmea_getinfo.out")

        # getresponse(module, 1)
    
        set_autorun(serial_port, True)
    
        # run_script(serial_port, "canary.out")
        # stop_script(serial_port)
        # counter = 0
        # while(script_is_running(serial_port)):
        #     print "Script still running"
        #     counter += 1
        #     if counter > 20:
        #         reset(serial_port)
        #         break
        # if counter > 20:
        #     print("Not running main script as module was reset")
        # else:
        #     run_script(serial_port, "loader.out")

        try:
            run_script(serial_port, "loader.out")
        except ValueError as e:
            print("Error starting script. Resetting module.")
            reset(serial_port)
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

    if args.zip_files:
        zip_files()
    else:
        transfer_and_build_files(args.directory, not args.no_initial_reset, args.force_all_files, args.loader, args.transfer_file)
