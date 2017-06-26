import time
import serial
import os


def get_response(serial_port, sleep_time=0.25):
    time.sleep(sleep_time)
    response = ""
    while serial_port.inWaiting():
        response += serial_port.readline()
    print "Response: " + str(response)
    return response


def put_file(serial_port, filename, file_contents):
    # serial_port.write("ATE0\r\n")
    # get_response(serial_port)

    serial_port.write('AT+CFTRANRX="c:/%s",%i\r\n' %
                      (filename, len(file_contents)))

    get_response(serial_port, 2)

    serial_port.write(file_contents)
    response = get_response(serial_port, 1)
    if not "OK" in response:
        raise ValueError(response)

    # serial_port.write("ATE1\r\n")
    # get_response(serial_port)


def change_dir(serial_port, directory):
    serial_port.write('AT+FSCD=%s\r\n' % directory)
    response = get_response(serial_port)
    if not "OK" in response:
        raise ValueError(response)


def compile_file(serial_port, filename):
    # serial_port.write("ATE0\r\n")

    serial_port.write('AT+CSCRIPTCL="c:/%s"\r\n' % filename)
    response = get_response(serial_port, 2)
    if not "OK" in response:
        raise ValueError(response)


def delete_file(serial_port, filename):
    # serial_port.write("ATE0\r\n")
    # get_response(serial_port)
    serial_port.write('AT+FSDEL="%s"\r\n' % filename)
    response = get_response(serial_port)
    if not "OK" in response:
        raise ValueError(response)
    # serial_port.write("ATE1\r\n")
    # get_response(serial_port)


def ls(serial_port):
    serial_port.write('AT+FSLS\r\n')
    response = get_response(serial_port)


def run_script(serial_port, script):
    serial_port.write('AT+CSCRIPTSTART="%s"\r\n' % script)
    response = get_response(serial_port)
    if not "OK" in response:
        raise ValueError(response)


def stop_script(serial_port, script):
    serial_port.write('AT+CSCRIPTSTOP="%s"\r\n' % script)
    response = get_response(serial_port)
    if not "OK" in response:
        raise ValueError(response)


def read_all(serial_port):
    while True:
        get_response(serial_port, 5)


def copy_file(serial_port, src, dest):
    serial_port.write('AT+FSCOPY="%s","%s"\r\n' % (src, dest))
    response = get_response(serial_port)
    if not "OK" in response:
        raise ValueError(response)


def set_autorun(serial_port, on_flag=True):
    on_off = "0"
    if on_flag is True:
        on_off = "1"
    serial_port.write('AT+CSCRIPTAUTO=%s\r\n' % on_off)
    response = get_response(serial_port)
    if not "OK" in response:
        raise ValueError(response)


def stop_script(serial_port):
    serial_port.write('AT+CSCRIPTSTOP\r\n')
    response = get_response(serial_port)