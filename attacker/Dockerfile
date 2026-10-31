# Attack source: nmap (scanning), hping3 (crafted / flood packets), hydra (password guessing)
FROM debian:12.15-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends nmap hping3 hydra curl iputils-ping \
 && rm -rf /var/lib/apt/lists/*

CMD ["sleep", "infinity"]
