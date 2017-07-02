from atlib import *
import time


#module = serial.Serial("/dev/cu.usbserial-A105NJ7M",  115200, timeout=5)
module = serial.serial_for_url("rfc2217://10.1.1.77:9991", 115200, timeout=5)
# module = serial.Serial("/dev/ttyUSB0",  115200, timeout=5)

try:
    time.sleep(3)
    get_response(module)
    change_dir(module, "c:/")
    files = [
        "ati_parser.lua",
        # "reporter.lua",
        "tcp_client.lua",
        "encapsulation.lua",
        "nmea_getinfo.lua",
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

    time.sleep(3)

    for file in files:  # os.listdir("."):
        compile_file(module, file)

    for file in files:  # os.listdir("."):
        delete_file(module, file)

    delete_file(module, "autorun.out")

    # compile_file(module, "reporter.lua")
    ls(module)

    run_script(module, "reporter.out")
    stop_script(module)
    while(script_is_running(module)):
        print "Script still running"
    try:
        run_script(module, "nmea_getinfo.out")
    except ValueError as error:
        get_response(module, 2)
        get_response(module, 2)
        run_script(module, "nmea_getinfo.out")
    #copy_file(module, "nmea_getinfo.out", "autorun.out")

    set_autorun(module, True)

    read_all(module)

finally:
    module.close()
