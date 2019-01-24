FROM openresty/openresty:xenial
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*
