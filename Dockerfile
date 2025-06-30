FROM debian:bookworm-backports

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update &&     apt-get install -y --no-install-recommends     wireguard iproute2 iptables curl cron procps zstd &&     apt-get clean && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/
COPY configs/ /etc/home-wg/
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME /etc/home-wg          # bind-mount real config
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
