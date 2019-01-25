# Nginx Lua Redis Rate Measuring

A [Lua](https://www.lua.org/) library to provide rate measurement using [nginx](https://nginx.org/) + redis. This lib was inspired at a Cloudflare's post: [How we built rate limiting capable of scaling to millions of domains](https://blog.cloudflare.com/counting-things-a-lot-of-different-things/)

# Use case: distributed throttling

Nginx has already [a rate limiting feature](https://www.nginx.com/blog/rate-limiting-nginx/) but it is restricted by the local node. Once you have more than one server behind a load balancer this won't work as expected, so you can use [redis](https://redis.io/) as a distributed storage to keep the rating data.

```lua
local redis_client = redis_cluster:new(config)
local rate, err = redis_rate.measure(redis_client, ngx.var.arg_token)
if err then
    ngx.log(ngx.ERR, "err: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

if rate > 10 then
    ngx.exit(ngx.HTTP_FORBIDDEN)
end

ngx.say(rate)
```

# Use case: tests

You can run the throttling example locally and also test it. Open up a terminal tab to run the servers.

```bash
make up
```
Open another terminal tab and perform some tests

```bash
# it allows 10 req/s instantaneously
for i in {1..10}; do curl "http://localhost:8080/lua_content?token=secretvalue"; done

# it allows 10 req/s in a normal distribution
for i in {1..20}; do sleep 6 && curl "http://localhost:8080/lua_content?token=secretvalue1"; done

# it forbids 12 req/s instantaneously (after the 10th)
for i in {1..12}; do curl "http://localhost:8080/lua_content?token=secretvalue2"; done

# it forbids 12 req/s in a normal distribution (60/12 = 5s)
for i in {1..50}; do sleep 5 && curl "http://localhost:8080/lua_content?token=secretvalue3"; done
```
