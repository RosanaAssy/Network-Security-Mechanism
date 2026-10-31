# Network Security Mechanism — Suricata IDS Lab

A small Docker lab for the ISDI 509 mini-project. It runs the **Suricata** IDS
with the **EveBox** dashboard and tests it with three attacks and one evasion.

> Everything runs on an isolated Docker network with no internet access.
> Only the lab's own containers are attacked.

## Lab

| Container | Address | Role |
|-----------|---------|------|
| `victim` | 172.28.0.10 | SSH + web server (the protected host) |
| `attacker` | 172.28.0.20 | nmap, hping3, hydra |
| `client` | 172.28.0.30 | normal web + SSH traffic |
| `suricata` | host | Suricata 7.0.16, watches the lab network |
| `evebox` | localhost:5636 | EveBox 0.29.0 dashboard |

## Requirements

- Linux with Docker and Docker Compose
- About 1.5 GB free RAM and 4 GB free disk

## Start

```bash
docker compose up -d --build
```

The first start downloads the ET Open rules (needs internet once).
Wait about a minute, then open **http://localhost:5636**.

## Attacks

| # | Attack | Command | Expected alert |
|---|--------|---------|----------------|
| 1 | Port scan | `docker compose exec attacker sh /attacks/scan.sh` | `LAB SCAN` (sid 1000001) |
| 2 | SSH brute force | `docker compose exec attacker sh /attacks/bruteforce.sh` | `LAB BRUTEFORCE` (sid 1000002) |
| 3 | SYN flood | `docker compose exec attacker sh /attacks/flood.sh` | `LAB DOS` (sid 1000003) |
| E | Slow scan (evasion) | `docker compose exec attacker sh /attacks/slowscan.sh` | no alert |

Any alert from the client (172.28.0.30) is a false alarm.

To run every attack 5 times and print a results table:

```bash
./run_tests.sh 5
```

## Stop

```bash
docker compose down       # stop
docker compose down -v    # stop and delete all data
```

## Files

```
docker-compose.yml     the lab
run_tests.sh           runs all attacks and prints the results
results.txt            results of the last run
suricata/local.rules   the three custom rules
suricata/start.sh      rule update + Suricata start
attacks/               attack scripts + password list
victim/ attacker/ client/   container images
```

## Author

Rosana Assy
