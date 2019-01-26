# Resty Redis Rate

A [Lua](https://www.lua.org/) library to provide rate measurement using [nginx](https://nginx.org/) + Redis. This lib was inspired on Cloudflare's post [How we built rate limiting capable of scaling to millions of domains.](https://blog.cloudflare.com/counting-things-a-lot-of-different-things/)

> You can found more about why and when this library was created [here.](https://leandromoreira.com.br/2019/01/25/how-to-build-a-distributed-throttling-system-with-nginx-lua-redis/).

# Use case: distributed throttling

Nginx has already [a rate limiting feature](https://www.nginx.com/blog/rate-limiting-nginx/) but it is restricted by the local node. Once you have more than one server behind a load balancer this won't work as expected, so you can use [redis](https://redis.io/) as a distributed storage to keep the rating data.

```lua
local redis_client = redis_cluster:new(config)
-- let's say we'll use the ?token=<value> as the key to rate limit
local rate, err = redis_rate.measure(redis_client, ngx.var.arg_token)
if err then
    ngx.log(ngx.ERR, "err: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- once we hit more than 10 reqs/m we'll reply 403
if rate > 10 then
    ngx.exit(ngx.HTTP_FORBIDDEN)
end

ngx.say(rate)
```

### Tests result

We ran three different experiments constrained by a `rate limit of 10 req/minute`:

1.  `Experiment1:` 1 reqs/second
1.  `Experiment2:` 1/6 reqs/second
1.  `Experiment3:` 1/5 reqs/second

![nginx redis throttling exprimentes graph result](/img/graph.png "A graph with experiments results")

> All the data points above the rate limit (the red line) resulted in forbidden responses.

You can run the throttling example locally, open up a terminal tab to run the servers.

> **Make sure you have `docker` and `docker-compose` installed.**

```bash
make up
```
Open another terminal tab and perform the experiments:

```bash
# Experiment 1
for i in {1..120}; do curl "http://localhost:8080/lua_content?token=Experiment1" && sleep 1; done

# Experiment 2
for i in {1..20}; do curl "http://localhost:8080/lua_content?token=Experiment2" && sleep 6; done

# Experiment 3
for i in {1..24}; do curl "http://localhost:8080/lua_content?token=Experiment3" && sleep 5; done
```
