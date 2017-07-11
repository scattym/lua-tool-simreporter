from atlib import *
import time


#module = serial.Serial("/dev/cu.usbserial-A105NJ7M",  115200, timeout=5)
module = serial.serial_for_url("rfc2217://10.1.1.5:9990", 115200, timeout=5)
# module = serial.Serial("/dev/ttyUSB0",  115200, timeout=5)

try:
    get_response(module)
    change_dir(module, "c:/")
    files = [
        "at_abs.lua",
        #         "at_commands.lua",
        #         "canary.lua",
        #         "network_setup.lua",
        #         "reporter.lua",
        #         "tcp_client.lua",
        #         "encapsulation.lua",
        #         "nmea_getinfo.lua",
        #         "util.lua",
    ]
    stop_script(module)
    while(script_is_running(module)):
        print "Script still running"
    set_autorun(module, False)
    for file in files:  # os.listdir("."):
        if os.path.isfile(file):
            if "lua" in file:
                print "Putting file " + file
                with open(file, 'r') as content_file:
                    content = content_file.read()
                    put_file(module, file, content)
                    # delete_file(module, file)

    # for file in files:  # os.listdir("."):
    #     compiled = file.replace(".lua", ".out")
    #     delete_file(module, compiled)

    for file in files:  # os.listdir("."):
        compile_file(module, file)

    # for file in files:  # os.listdir("."):
    #    delete_file(module, file)

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
    copy_file(module, "nmea_getinfo.out", "autorun.out")

    # getresponse(module, 1)

    set_autorun(module, True)

    run_script(module, "canary.out")
    stop_script(module)
    while(script_is_running(module)):
        print "Script still running"
    run_script(module, "nmea_getinfo.out")

    read_all(module)

finally:
    module.close()
