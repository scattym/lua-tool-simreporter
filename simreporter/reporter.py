from atlib import *


module = serial.Serial("/dev/cu.usbserial-A105NJ7M",  115200, timeout=5)
try:
    change_dir(module, "c:/")
    files = ["reporter.lua", "tcp_client.lua", "encapsulation.lua"]
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

    # for file in files:  # os.listdir("."):
    #    delete_file(module, file)

    # compile_file(module, "reporter.lua")
    ls(module)

    run_script(module, "reporter.out")

    read_all(module)

finally:
    module.close()
