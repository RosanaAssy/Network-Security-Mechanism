#!/bin/sh
# Evasion variant of scenario 1: the same SYN scan, but one probe per second
# (stays under the "20 SYNs in 10 seconds" threshold of rule 1000001). Takes about 1 minute.
nmap -sS --scan-delay 1s -p 1-60 172.28.0.10
