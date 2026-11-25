FROM postgres:18.7-bookworm
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 python3-cryptography \
 && rm -rf /var/lib/apt/lists/* \
 && install -d -o postgres -g postgres /var/lib/postgresql/wal-archive
