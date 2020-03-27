#!/usr/local/bin/python3

import time
from fritzconnection.lib.fritzstatus import FritzStatus

fc = FritzStatus(address='192.168.178.1')
while True:
    print(
        f"Linked: {fc.is_connected} -- Connected: {fc.is_linked} -- max bit rate: {fc.str_max_bit_rate} -- trans rate: {fc.str_transmission_rate}")
    time.sleep(2)
