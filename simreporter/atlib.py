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

    serial_port.write('AT+CFTRANRX="%s",%i\r\n' %
                      (filename, len(file_contents)))

    response = get_response(serial_port, 0.5)
    if ">" not in response:
        raise ValueError(response)

    # serial_port.write(file_contents)
    for i in range(0, len(file_contents), 8192):
        serial_port.write(file_contents[i:i+8192])
        time.sleep(0.5)
    response = get_response(serial_port, 1.5)
    if "OK" not in response:
        raise ValueError(response)

    # serial_port.write("ATE1\r\n")
    # get_response(serial_port)


def slicen(s, n, truncate=False):
    assert n > 0
    while len(s) >= n:
        yield s[:n]
        s = s[n:]
    if len(s) and not truncate:
        yield s


def put_binary_file(serial_port, filename, file_contents):
    serial_port.write("ATE0\r\n")
    get_response(serial_port)

    serial_port.write('AT+CFTRANRX="%s",%i\r\n' %
                      (filename, len(file_contents)))

    response = get_response(serial_port, 3)
    print "Respnose is " + response
    get_response(serial_port)

    for i in range(0, len(file_contents), 2048):
        serial_port.write(file_contents[i:i+2048])
        time.sleep(1)
    #serial_port.write(file_contents)
    #time.sleep(10)
    serial_port.write("ATE1\r\n")
    response = get_response(serial_port, 5)
    if "OK" not in response:
        raise ValueError(response)


def change_dir(serial_port, directory):
    serial_port.write('AT+FSCD=%s\r\n' % directory)
    response = get_response(serial_port)
    if "OK" not in response:
        raise ValueError(response)


def compile_file(serial_port, filename, retry = True):
    # serial_port.write("ATE0\r\n")

    serial_port.write('AT+CSCRIPTCL="%s"\r\n' % filename)
    response = get_response(serial_port, 3)
    if "ERROR" in response and retry is True:
        serial_port.write('AT+CSCRIPTCL="%s"\r\n' % filename)
        response = get_response(serial_port, 3)

    if "ERROR" in response:
        raise ValueError(response)


def delete_file(serial_port, filename):
    # serial_port.write("ATE0\r\n")
    # get_response(serial_port)
    serial_port.write('AT+FSDEL="%s"\r\n' % filename)
    response = get_response(serial_port, 0.5)
    if response == "":
        raise ValueError(response)
    # serial_port.write("ATE1\r\n")
    # get_response(serial_port)


def ls(serial_port):
    serial_port.write('AT+FSLS\r\n')
    response = get_response(serial_port)


def run_script(serial_port, script):
    serial_port.write('AT+CSCRIPTSTART="%s"\r\n' % script)
    response = get_response(serial_port, 1)
    if "OK" not in response:
        raise ValueError(response)


def stop_script(serial_port, script):
    serial_port.write('AT+CSCRIPTSTOP="%s"\r\n' % script)
    response = get_response(serial_port, 1)
    if response == "":
        raise ValueError(response)


def script_is_running(serial_port):
    serial_port.write('AT+CSCRIPTSTOP?\r\n')
    response = get_response(serial_port, 1)
    if response == "":
        raise ValueError(response)
    if "+CSCRIPTSTOP:" in response:
        return True
    return False


def read_all(serial_port):
    while True:
        get_response(serial_port, 5)


def copy_file(serial_port, src, dest):
    serial_port.write('AT+FSCOPY="%s","%s"\r\n' % (src, dest))
    response = get_response(serial_port, 0.75)
    if "OK" not in response:
        raise ValueError(response)


def set_autorun(serial_port, on_flag=True):
    on_off = "0"
    if on_flag is True:
        on_off = "1"
    serial_port.write('AT+CSCRIPTAUTO=%s\r\n' % on_off)
    response = get_response(serial_port)
    if "OK" not in response:
        raise ValueError(response)


def stop_script(serial_port):
    serial_port.write('AT+CSCRIPTSTOP\r\n')
    response = get_response(serial_port)


def reset(serial_port):
    serial_port.write('AT+CRESET\r\n')
    response = get_response(serial_port)


def mkdir(serial_port, directory):
    serial_port.write('AT+FSMKDIR=%s\r\n' % directory)
    response = get_response(serial_port)
