#!/usr/bin/env bash
set -euo pipefail

CFG_DIR=/etc/home-wg
CONF="${CFG_DIR}/wg0.conf"
LAN_IFACE=${LAN_IFACE:-eth0}

chmod 600 "${CONF}" 2>/dev/null || true
sysctl -w net.ipv4.ip_forward=1

# --- stop any stale interface using the SAME conf file ------------
if ip link show wg0 &>/dev/null ; then
  echo "[INFO] wg0 already present – removing stale interface"
  wg-quick down "${CONF}" || ip link delete wg0 || true
fi

# --- bring it back up --------------------------------------------
wg-quick up "${CONF}"

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
exec tail -f /dev/null

