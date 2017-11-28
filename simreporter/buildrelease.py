#!/usr/bin/env python

from atlib import *
import time
import os
import os.path
import argparse
import tempfile
import ConfigParser
import shutil
import datetime

config = ConfigParser.RawConfigParser()


def zip_files(zip_file):
    zip_file_list = []
    for file_name in files:
        zip_file_list.append(file_name.replace(".lua", ".out"))
    cmd = "minizip %s %s" % (zip_file, " ".join(zip_file_list))
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


def transfer_and_build_files(directory, initial_reset, force_all_files, send_loader, only_file, config_file):
    serial_port = open_config_port(config_file=config_file)

    try:
        set_autorun(serial_port, False)
        if initial_reset:
            reset(serial_port)
            response = get_response(serial_port, 2)
            serial_port.close()
            print("Sleeeping")
            time.sleep(12)
            print("Resuming")
            serial_port.open()
            while "PB DONE" not in response and "CME ERROR" not in response:
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
        try:
            os.mkdir("lastbuild")
        except OSError as err:
            print("Directory already present or can't create.")
        compile_files = []

        for filename in files:  # os.listdir("."):
            if only_file is None or only_file == filename:
                if os.path.isfile(filename):
                    if "lua" in filename:
                        if file_is_newer_than(
                                filename, "lastbuild/" + filename) or force_all_files:
                            print("Putting file %s" % filename)
                            with open(filename, 'r') as content_file:
                                content = content_file.read()
                                put_file(
                                    serial_port,
                                    "c:/libs/" +
                                    directory +
                                    "/" +
                                    filename,
                                    content)
                                # delete_file(module, file)

                            compile_files.append(filename)
                        else:
                            print("File %s is not newer than last uploaded version" % (
                                filename
                            ))
                    # delete_file(module, file)

        # for file in files:  # os.listdir("."):
        #     compiled = file.replace(".lua", ".out")
        #     delete_file(module, compiled)
        time.sleep(2)
        for filename in compile_files:  # os.listdir("."):
            compile_file(serial_port, "c:/libs/" + directory + "/" + filename)

        for filename in compile_files:  # os.listdir("."):
            delete_file(serial_port, filename)

        try:
            os.mkdir("build")
        except OSError as err:
            print("Dir exists or can't create.")
        os.chdir("build")
        for filename in compile_files:
            built_file = filename.replace(".lua", ".out")
            data = get_file(serial_port, "c:/libs/%s/%s" % (directory, built_file))
            f = open("%s" % (os.path.basename(built_file)), 'w')
            f.write(data)
            f.close()
            touch("../lastbuild/" + filename)

        if len(compile_files) == 0:
            print("Nothing changed in this build")
        else:
            zip_files(full_file)

    finally:
        serial_port.close()


if __name__ == '__main__':

    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        '-c',
        '--config-file',
        help="The config file to use.",
        default="builder.cfg",
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

    config.read(args.config_file)

    files = config.get('release', 'files').split(",")
    date = datetime.datetime.utcnow()
    date_str = date.strftime("%Y%m%d")
    full_file = ""
    for counter in range(0, 100):
        counter_str = str(counter).zfill(2)
        full_file = "%s%s%s" % (date_str, counter_str, ".zip")
        if not os.path.isfile("build/%s" % full_file):
            break
    print("Full file is %s" % full_file)

    transfer_and_build_files(
        args.directory,
        not args.no_initial_reset,
        args.force_all_files,
        args.loader,
        args.transfer_file,
        args.config_file,
    )


