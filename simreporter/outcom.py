#!/usr/bin/env python

import math
import struct

from atlib import *
import time
import os
import os.path
import argparse
import json
from random import randint

serial_port = open_config_port()


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
    for _ in range(0,100):
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
            response = get_response(serial_port, 0.3)

        while "true" not in response:
            print("Waiting for module transfer to complete.")
            response = get_response(serial_port, 2)

    read_all(serial_port)

    # report = models.ForeignKey(device_models.Device, on_delete=models.CASCADE)
    # engine_rpm = models.FloatField(null=True, blank=True)
    # vehicle_speed = models.FloatField(null=True, blank=True)
    # throttle_position = models.FloatField(null=True, blank=True)
    # intake_air_temp = models.FloatField(null=True, blank=True)
    # run_time = models.FloatField(null=True, blank=True)
    # fuel_tank_level = models.FloatField(null=True, blank=True)
    # distance_traveled = models.FloatField(null=True, blank=True)
    # ambient_air_temperature = models.FloatField(null=True, blank=True)


data = {
    "obdii": {
        "engine_rpm": randint(800, 1200),
        "vehicle_speed": randint(0, 120),
        "throttle_position": randint(0, 90),
        "intake_air_temp": randint(19, 36),
        "run_time": randint(0, 1000),
        "fuel_tank_level": randint(0, 100),
        "distance_traveled": randint(10, 200),
        "ambient_air_temperature": randint(40, 80)
    }
}
split_message(json.dumps(data))
