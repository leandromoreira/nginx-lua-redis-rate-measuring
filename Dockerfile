FROM openresty/openresty:xenial

RUN apt-get update \
    && apt-get install -y \
       git \
    && mkdir /src \
    && cd /src \
    && git config --global url."https://".insteadOf git:// \
    && luarocks install lua-resty-redis \
    && luarocks install lua-resty-lock \
    && git clone https://github.com/steve0511/resty-redis-cluster.git \
    && cd resty-redis-cluster/ \
    && git checkout 8d7b96d002337c38d71859e5f04f76b413aa5c29 \
    && luarocks make \
    && gcc -fPIC -shared -I/usr/local/openresty/luajit -o /usr/local/openresty/luajit/lib/lua/5.1/librestyredisslot.so src/redis_slot.c \
    && rm -Rf /src
