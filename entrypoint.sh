#!/usr/bin/env bash
set -euo pipefail

CFG_DIR=/etc/home-wg           # holds wg0.conf + keys
LAN_IFACE=${LAN_IFACE:-eth0}   # allow override

# ---------- 1  kernel tweaks ----------
sysctl -w net.ipv4.ip_forward=1

# ---------- 2  start WireGuard ----------
wg-quick up "${CFG_DIR}/wg0.conf"

# ---------- 3  NAT VPN → apartment LAN ----------
iptables -t nat -C POSTROUTING -s 10.10.0.0/24 -o "${LAN_IFACE}" -j MASQUERADE 2>/dev/null \
  || iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o "${LAN_IFACE}" -j MASQUERADE

# ---------- 4  DuckDNS cron ----------
cat >/etc/cron.d/duckdns <<EOF
*/5 * * * * root /usr/bin/curl -s "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=$(curl -s https://ipv4.icanhazip.com)&ipv6=\$(ip -6 addr show ${LAN_IFACE} scope global | awk '/inet6/ {print \$2; exit}' | cut -d/ -f1)" | logger -t duckdns
EOF
chmod 644 /etc/cron.d/duckdns
cron

# ---------- 5  foreground logs ----------
exec tail -f /var/log/syslog

