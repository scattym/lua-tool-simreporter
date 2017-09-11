from atlib import *
import time


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

    mkdir(module, "libs")
    change_dir(module, "libs")
    mkdir(module, "201709101")
    change_dir(module, "201709101")
    set_autorun(module, False)
    files = [
        "at_abs.lua",
        "at_commands.lua",
        "canary.lua",
        "device.lua",
        "encapsulation.lua",
        "network_setup.lua",
        "nmea_getinfo.lua",
        "reporter.lua",
        "tcp_client.lua",
        "util.lua",
        "basic_threads.lua"
    ]
    compile_files = []
    stop_script(module)
    counter = 0
    while(script_is_running(module)):
        print "Script still running"
        counter += 1
        if counter > 30:
            print "Script not stopping, resetting module."
            reset(module)
            response = get_response(module, 2)
            while("PB DONE" not in response and "CME_ERROR" not in response and "CME ERROR" not in response):
                print("Waiting for module to start.")
                response = get_response(module, 2)
            time.sleep(5)
            print("Module now ready.")
            break

    for file in files:  # os.listdir("."):
        if os.path.isfile(file):
            if "lua" in file:
                if file_is_newer_than(file, "lastupload/" + file):
                    print "Putting file " + file
                    with open(file, 'r') as content_file:
                        content = content_file.read()
                        put_file(module, "c:/libs/201709101/" + file, content)
                        # delete_file(module, file)
                    touch("lastupload/" + file)
                    compile_files.append(file)
                else:
                    print "File %s is not newer than last uploaded version" % (
                        file
                    )

    # for file in files:  # os.listdir("."):
    #     compiled = file.replace(".lua", ".out")
    #     delete_file(module, compiled)

    for file in compile_files:  # os.listdir("."):
        compile_file(module, "c:/libs/201709101/" + file)

    for file in compile_files:  # os.listdir("."):
        delete_file(module, "c:/libs/201709101/" + file)

    change_dir(module, "c:/")
    with open("loader.lua", 'r') as content_file:
        content = content_file.read()
        put_file(module, "c:/loader.lua", content)
    compile_file(module, "loader.lua")
    delete_file(module, "autorun.out")

    # compile_file(module, "reporter.lua")
    ls(module)

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
    copy_file(module, "loader.out", "autorun.out")

    # getresponse(module, 1)

    set_autorun(module, True)

    run_script(module, "canary.out")
    stop_script(module)
    counter = 0
    while(script_is_running(module)):
        print "Script still running"
        counter += 1
        if counter > 20:
            reset(module)
            break
    if counter > 20:
        print("Not running main script as module was reset")
    else:
        run_script(module, "loader.out")

    read_all(module)

finally:
    module.close()
