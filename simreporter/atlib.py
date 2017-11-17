import time
import serial
import os
import ConfigParser


def open_config_port(speed=115200):
    config = ConfigParser.RawConfigParser()
    config.read('release.cfg')
    device = config.get('release', 'device')
    try:
        serial_port = serial.serial_for_url(device, speed, timeout=5)
    except ValueError as err:
        if err.message == "remote rejected value for option 'baudrate'":
            serial_port = serial.serial_for_url(device, timeout=5)
    return serial_port


def get_response(serial_port, sleep_time=0.25):
    time.sleep(sleep_time)
    response = ""
    while serial_port.inWaiting():
        response += serial_port.readline()
    print("Response: " + str(response))
    return response


def send_command(serial_port, command):
    serial_port.write('%s\r\n' % command)


def parse_file_length_message(msg):
    print("Parsing %s" % msg)
    msg = msg.replace('\r', '').replace('\n', '')
    message_arr = msg.split(',')
    return int(message_arr[1])


def parse_file_payload(payload):
    return_data = ""
    start = 0
    # line_end = 0
    i = 0
    while i < len(payload):
        if payload[i] == '\n':
            line_end = i
            if "DATA" in payload[start:i]:
                size = parse_file_length_message(payload[start:i])
                if size != 0:
                    print ("size is %s" % (size,))
                    return_data += payload[line_end+1:line_end+1+size]
                    start = line_end+1+size
                    i = start
            else:
                i = i + 1
                start = i
        else:
            i = i + 1
    return return_data


def get_file(serial_port, src_file):
    serial_port.write('AT+CATR=0\r\n')
    response = get_response(serial_port)
    print("response is %s" % response)

    serial_port.write('AT+CFTRANTX="%s"\r\n' % src_file)
    finished = False
    overall = ""
    while not finished:
        data = get_response(serial_port)
        print("Data is ", data)
        overall = overall + data
        if "+CFTRANTX: 0" in data:
            finished = True

    data = parse_file_payload(overall)
    print("Data is >%s<" % data)
    return data


def get_file_xmodem(serial_port, src_file):
    serial_port.write('AT+CTXFILE="%s"\r\n' % src_file)


def put_file(serial_port, filename, file_contents):
    # serial_port.write("ATE0\r\n")
    # get_response(serial_port)

    serial_port.write('ATE0\r\n')
    get_response(serial_port, 0.25)
    serial_port.write('AT+CFTRANRX="%s",%i\r\n' %
                      (filename, len(file_contents)))

    response = get_response(serial_port, 0.5)
    if ">" not in response:
        raise ValueError(response)

    # serial_port.write(file_contents)
    file_length = len(file_contents)
    block_size = 2048
    for i in range(0, file_length, block_size):
        end = i + block_size
        if end >= file_length:
            end = file_length
            print(file_contents[end-5:end])
        print("Sending range %s to %s" % (i, end))
        serial_port.write(file_contents[i:end])
        serial_port.flush()
        time.sleep(0.5)
    serial_port.write('\r\n')
    response = get_response(serial_port, 4)
    if "OK" not in response:
        raise ValueError(response)
    serial_port.write('ATE1\r\n')
    get_response(serial_port, 0.25)

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
    print("Respnose is %s" % (response,))
    get_response(serial_port)

    for i in range(0, len(file_contents), 2048):
        serial_port.write(file_contents[i:i+2048])
        time.sleep(1)
    # serial_port.write(file_contents)
    # time.sleep(10)
    serial_port.write("ATE1\r\n")
    response = get_response(serial_port, 5)
    if "OK" not in response:
        raise ValueError(response)


def change_dir(serial_port, directory):
    serial_port.write('AT+FSCD=%s\r\n' % directory)
    response = get_response(serial_port)
    if "OK" not in response:
        raise ValueError(response)


def compile_file(serial_port, filename, retry=True):
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
    get_response(serial_port)


def run_script(serial_port, script):
    serial_port.write('AT+CSCRIPTSTART="%s"\r\n' % script)
    response = get_response(serial_port, 1)
    if "OK" not in response:
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


def stop_script(serial_port, script):
    serial_port.write('AT+CSCRIPTSTOP="%s"\r\n' % script)
    response = get_response(serial_port, 1)
    if response == "":
        raise ValueError(response)


# def stop_script(serial_port):
#     serial_port.write('AT+CSCRIPTSTOP\r\n')
#     response = get_response(serial_port)


def reset(serial_port):
    serial_port.write('AT+CRESET\r\n')
    response = get_response(serial_port)


def mkdir(serial_port, directory):
    serial_port.write('AT+FSMKDIR=%s\r\n' % directory)
    response = get_response(serial_port)
