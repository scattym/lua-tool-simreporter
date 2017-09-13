#!/usr/bin/env python

from atlib import *
import time
import os
import os.path
import argparse

# module = serial.Serial("/dev/cu.usbserial-A105NJ7M",  115200, timeout=5)
serial_port = serial.serial_for_url("rfc2217://10.1.1.5:9990", 115200, timeout=5)
# module = serial.Serial("/dev/ttyUSB0",  115200, timeout=5)


def touch(fname, times=None):
    with open(fname, 'a'):
        os.utime(fname, times)


def file_is_newer_than(file1, file2):
    if os.path.isfile(file1) and os.path.isfile(file2):
        return os.path.getctime(file1) > os.path.getctime(file2)
    return True


def transfer_and_build_filers(dir):
    try:
        get_response(serial_port)
        change_dir(serial_port, "c:/")
    
        mkdir(serial_port, "libs")
        change_dir(serial_port, "libs")
        mkdir(serial_port, dir)
        change_dir(serial_port, dir)
        set_autorun(serial_port, False)
        files = [
            "at_abs.lua",
            "at_commands.lua",
            "basic_threads.lua",
            "canary.lua",
            "device.lua",
            "encapsulation.lua",
            "json.lua",
            "network_setup.lua",
            "nmea_getinfo.lua",
            "reporter.lua",
            "system.lua",
            "tcp_client.lua",
            "util.lua",
            "unzip.lua",
        ]
        compile_files = []
        stop_script(serial_port)
        counter = 0
        while(script_is_running(serial_port)):
            print "Script still running"
            counter += 1
            if counter > 30:
                print "Script not stopping, resetting module."
                reset(serial_port)
                response = get_response(serial_port, 2)
                while("START" not in response):
                    print("Waiting for module to start.")
                    response = get_response(serial_port, 2)
                time.sleep(15)
                print("Module now ready.")
                break
    
        for filename in files:  # os.listdir("."):
            if os.path.isfile(filename):
                if "lua" in filename:
                    if file_is_newer_than(filename, "lastupload/" + filename):
                        print "Putting file " + filename
                        with open(filename, 'r') as content_file:
                            content = content_file.read()
                            put_file(serial_port, "c:/libs/base/" + filename, content)
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
    
        for filename in compile_files:  # os.listdir("."):
            compile_file(serial_port, "c:/libs/base/" + filename)
    
        for filename in compile_files:  # os.listdir("."):
            delete_file(serial_port, filename)
    
        change_dir(serial_port, "c:/")
        with open("loader.lua", 'r') as content_file:
            content = content_file.read()
            put_file(serial_port, "c:/loader.lua", content)
        compile_file(serial_port, "loader.lua")
        delete_file(serial_port, "autorun.out")
        delete_file(serial_port, "loader.lua")
    
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
        copy_file(serial_port, "loader.out", "autorun.out")
    
        # getresponse(module, 1)
    
        set_autorun(serial_port, False)
    
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
    
        run_script(serial_port, "loader.out")
        read_all(serial_port)
    
    finally:
        serial_port.close()

if __name__ == '__main__':

    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        '-d',
        '--directory',
        help="The target directory in libs. Defaults to base.",
        default="base"
    )

    args = parser.parse_args()

    transfer_and_build_filers(args.directory)
