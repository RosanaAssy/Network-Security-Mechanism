#!/bin/bash
# Download the free ET Open rules, add our own lab rules, then start Suricata.
set -e

# Lab rules are merged into /var/lib/suricata/rules/suricata.rules.
# If there is no internet, keep the rules downloaded last time.
suricata-update --no-test --local /lab/local.rules \
  || echo "WARNING: rule download failed, using the rules from the last successful update"

# HOME_NET = the protected victim only, so every other host counts as EXTERNAL_NET.
# -k none: do not drop packets with bad checksums (common on Docker bridges).
exec /docker-entrypoint.sh \
  --af-packet=br-lab \
  -k none \
  --set "vars.address-groups.HOME_NET=[172.28.0.10]"
