#!/usr/bin/env python

import math
import struct

from atlib import *
import time
import os
import os.path
import argparse
import ConfigParser

config = ConfigParser.RawConfigParser()
config.read('release.cfg')
device = config.get('release', 'device')

# module = serial.Serial("/dev/cu.usbserial-A105NJ7M",  115200, timeout=5)
serial_port = serial.serial_for_url(device, 115200, timeout=5)
# module = serial.Serial("/dev/ttyUSB0",  115200, timeout=5)


def set_message_type(word, message_type):
    word = word + (message_type << 24)
    return word


def set_client_id(word, client_id):
    word = word + (client_id << 16)
    return word


def set_packet_num(word, packet_num):
    word = word + (packet_num << 8)
    return word


def set_packet_total(word, total):
    word = word + total
    return word


def build_header(message_type, client_id, packet_num, total):
    word1 = 0
    word1 = set_message_type(word1, 1)
    word1 = set_client_id(word1, 1)
    word1 = set_packet_num(word1, packet_num)
    word1 = set_packet_total(word1, total)
    return word1


def bytes2int(tb, order='big'):
    if order == 'big':
        seq = [0, 1, 2, 3]
    elif order == 'little':
        seq = [3, 2, 1, 0]
    i = 0
    for j in seq:
        i = (i << 8) + ord(tb[j])
    return i


def word32_to_bytes(word):
    # return struct.unpack('<' + 'B'*len(word), word) # [255, 16, 17]
    return bytes2int(word)


def split_message(message):
    packets = len(message)/4
    padding = 0
    if len(message) % 4 != 0:
        padding = 4 - len(message) % 4
        packets += 1
    print("Padding is %s" % (padding,))
    for i in range(0, padding):
        message = message + chr(0)

    for i in range(0, len(message), 4):
        header = build_header(1, 1, (i/4)+1, packets)
        data = word32_to_bytes(message[i:i+4])
        command = "AT+CSCRIPTCMD=%s,%s" % (header, data)
        send_command(serial_port, command)
        print get_response(serial_port, 0.05)

    read_all(serial_port)


split_message('{"engine_rpm": 1200}')
