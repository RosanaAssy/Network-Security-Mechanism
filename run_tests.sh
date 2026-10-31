#!/usr/bin/env bash
# ISDI 509 - run every attack scenario N times and print the results table.
#
# Usage:   ./run_tests.sh [RUNS]      (default 3 runs per scenario)
# Example: ./run_tests.sh 5
#
# For each scenario it records, per run: detected (custom rule fired?) and
# whether the benign client (172.28.0.30) caused any alert in that window.
# At the end it prints the summary table for your report.

set -u
RUNS="${1:-3}"
EVE=/var/log/suricata/eve.json

# --- helpers ---------------------------------------------------------------
# Count how many times a given signature id appears in eve.json right now.
count_sid() {
  docker compose exec -T suricata sh -c "grep -c '\"signature_id\":$1' $EVE 2>/dev/null" | tr -d '\r'
}
# Count alerts whose source is the benign client right now.
count_benign() {
  docker compose exec -T suricata sh -c \
    "grep '\"event_type\":\"alert\"' $EVE 2>/dev/null | grep -c '\"src_ip\":\"172.28.0.30\"'" | tr -d '\r'
}

# scenario: name | script | sid to watch | expected ("yes" = should detect)
run_scenario() {
  local name="$1" script="$2" sid="$3" expected="$4"
  local detected=0 missed=0 fp=0
  echo
  echo "========================================================"
  echo "  $name   (watching sid $sid, expect detection: $expected)"
  echo "========================================================"
  for i in $(seq 1 "$RUNS"); do
    local before after bbefore bafter
    before=$(count_sid "$sid")
    bbefore=$(count_benign)

    printf "  run %d/%d ... " "$i" "$RUNS"
    # bruteforce can hang on purpose; cap it at 25s so the loop keeps moving.
    if [ "$script" = "bruteforce.sh" ]; then
      timeout 25 docker compose exec -T attacker sh "/attacks/$script" >/dev/null 2>&1
      # timeout only stops the local docker client; hydra keeps running inside
      # the container unless we kill it there too.
      docker compose exec -T attacker sh -c 'kill $(pidof hydra) 2>/dev/null' >/dev/null 2>&1
    else
      docker compose exec -T attacker sh "/attacks/$script" >/dev/null 2>&1
    fi

    sleep 3   # let Suricata flush the alert to eve.json
    after=$(count_sid "$sid")
    bafter=$(count_benign)

    if [ "${after:-0}" -gt "${before:-0}" ]; then
      echo "DETECTED (sid $sid fired)"; detected=$((detected+1))
    else
      echo "not detected"; missed=$((missed+1))
    fi
    if [ "${bafter:-0}" -gt "${bbefore:-0}" ]; then fp=$((fp+1)); fi
    # Wait past the rules' 10 s threshold window so the next run is a clean trial
    # (otherwise a repeat alert is suppressed and looks like a miss).
    sleep 12
  done
  # store the row
  RESULTS="${RESULTS}${name}|${RUNS}|${detected}|${missed}|${fp}\n"
}

# --- checks ----------------------------------------------------------------
cd "$(dirname "$0")" || exit 1
if ! docker compose ps --status running 2>/dev/null | grep -q suricata; then
  echo "The lab is not running. Start it first:"
  echo "    docker compose up -d --build"
  exit 1
fi

echo "Running each scenario $RUNS time(s). This clears old alerts first."
# The engine must already be sniffing, or the first scenario's traffic is missed.
echo -n "Checking Suricata engine is ready"
ready=no
for _ in $(seq 1 45); do
  if docker compose logs suricata 2>/dev/null | grep -q "Engine started"; then ready=yes; break; fi
  echo -n "."; sleep 2
done
if [ "$ready" != yes ]; then
  echo
  echo "Suricata has not finished loading rules yet (no 'Engine started' in the log)."
  echo "Wait a minute after 'docker compose up' and run this again."
  exit 1
fi
echo " ready."
# Fresh slate so the counts are only from this test session.
# (Truncating the open file is fine for our grep-based counting; it only affects
#  EveBox's live view, which re-reads from the start after a truncation.)
docker compose exec -T suricata sh -c ": > $EVE" 2>/dev/null
sleep 2

RESULTS=""
run_scenario "1. Port scan (nmap SYN)"      scan.sh       1000001 yes
run_scenario "2. SSH brute force (hydra)"   bruteforce.sh 1000002 yes
run_scenario "3. SYN flood (hping3)"        flood.sh      1000003 yes
run_scenario "E. Slow scan (evasion)"       slowscan.sh   1000001 no

# --- results table ---------------------------------------------------------
echo
echo "############  RESULTS  ############"
printf "%-28s | %4s | %8s | %6s | %-13s\n" "Scenario" "Runs" "Detected" "Missed" "False alarms"
printf -- "-----------------------------+------+----------+--------+--------------\n"
printf "$RESULTS" | while IFS='|' read -r name runs det miss fp; do
  [ -z "$name" ] && continue
  printf "%-28s | %4s | %8s | %6s | %-13s\n" "$name" "$runs" "$det" "$miss" "$fp (benign client)"
done
echo
echo "Note: for 'E. Slow scan' DETECTED is the evasion FAILING - you want"
echo "      Detected = 0 there (the slow scan slips under the threshold)."
echo "Full alerts are in EveBox: http://localhost:5636"
