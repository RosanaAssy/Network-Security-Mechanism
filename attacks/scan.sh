#!/bin/sh
# Scenario 1 - network scanning: nmap SYN scan of the 1000 most common ports
nmap -sS -T4 --top-ports 1000 172.28.0.10
