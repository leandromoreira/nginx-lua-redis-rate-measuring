[![Build Status](https://travis-ci.org/leandromoreira/nginx-lua-redis-rate-measuring.svg?branch=master)](https://travis-ci.org/leandromoreira/nginx-lua-redis-rate-measuring) [![license](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg) [![Coverage Status](https://coveralls.io/repos/github/leandromoreira/nginx-lua-redis-rate-measuring/badge.svg)](https://coveralls.io/github/leandromoreira/nginx-lua-redis-rate-measuring)

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

# Pipeline and hash tag

We're using the combination of [pipeline](https://redis.io/topics/pipelining) and [hash tag](https://redis.io/topics/cluster-spec#keys-hash-tags) to perform all the commands in a single connection to redis cluster. You can see the tcpdump output showing the [three-way handshake](https://en.wikipedia.org/wiki/Handshaking#TCP_three-way_handshake) followed by the three commands requests `$get`, `$inc` and `$expire` and the redis response.

```bash
22:20:10.515457 IP (tos 0x0, ttl 64, id 38199, offset 0, flags [DF], proto TCP (6), length 60)
    172.31.0.3.49824 > 172.31.0.2.7000: Flags [S], cksum 0x5872 (incorrect -> 0xb9b9), seq 1010830934, win 29200, options [mss 1460,sackOK,TS val 170849 ecr 0,nop,wscale 7], length 0

22:20:10.515505 IP (tos 0x0, ttl 64, id 0, offset 0, flags [DF], proto TCP (6), length 60)
    172.31.0.2.7000 > 172.31.0.3.49824: Flags [S.], cksum 0x5872 (incorrect -> 0xfcda), seq 1496303914, ack 1010830935, win 28960, options [mss 1460,sackOK,TS val 170849 ecr 170849,nop,wscale 7], length 0

22:20:10.515518 IP (tos 0x0, ttl 64, id 38200, offset 0, flags [DF], proto TCP (6), length 52)
    172.31.0.3.49824 > 172.31.0.2.7000: Flags [.], cksum 0x586a (incorrect -> 0x9be2), seq 1, ack 1, win 229, options [nop,nop,TS val 170849 ecr 170849], length 0

22:20:10.515648 IP (tos 0x0, ttl 64, id 38201, offset 0, flags [DF], proto TCP (6), length 212)
    172.31.0.3.49824 > 172.31.0.2.7000: Flags [P.], cksum 0x590a (incorrect -> 0x7954), seq 1:161, ack 1, win 229, options [nop,nop,TS val 170849 ecr 170849], length 160
	0x0000:  4500 00d4 9539 4000 4006 4ca7 ac1f 0003  E....9@.@.L.....
	0x0010:  ac1f 0002 c2a0 1b58 3c40 0e57 592f c92b  .......X<@.WY/.+
	0x0020:  8018 00e5 590a 0000 0101 080a 0002 9b61  ....Y..........a
	0x0030:  0002 9b61 2a32 0d0a 2433 0d0a 6765 740d  ...a*2..$3..get.
	0x0040:  0a24 3239 0d0a 6e67 785f 7261 7465 5f6d  .$29..ngx_rate_m
	0x0050:  6561 7375 7269 6e67 5f7b 6c75 6967 697d  easuring_{luigi}
	0x0060:  5f31 390d 0a2a 320d 0a24 340d 0a69 6e63  _19..*2..$4..inc
	0x0070:  720d 0a24 3239 0d0a 6e67 785f 7261 7465  r..$29..ngx_rate
	0x0080:  5f6d 6561 7375 7269 6e67 5f7b 6c75 6967  _measuring_{luig
	0x0090:  697d 5f32 300d 0a2a 330d 0a24 360d 0a65  i}_20..*3..$6..e
	0x00a0:  7870 6972 650d 0a24 3239 0d0a 6e67 785f  xpire..$29..ngx_
	0x00b0:  7261 7465 5f6d 6561 7375 7269 6e67 5f7b  rate_measuring_{
	0x00c0:  6c75 6967 697d 5f32 300d 0a24 330d 0a31  luigi}_20..$3..1
	0x00d0:  3230 0d0a                                20..
22:20:10.517337 IP (tos 0x0, ttl 64, id 21067, offset 0, flags [DF], proto TCP (6), length 65)
    172.31.0.2.7000 > 172.31.0.3.49824: Flags [P.], cksum 0x5877 (incorrect -> 0xc55e), seq 1:14, ack 161, win 235, options [nop,nop,TS val 170849 ecr 170849], length 13
	0x0000:  4500 0041 524b 4000 4006 9028 ac1f 0002  E..ARK@.@..(....
	0x0010:  ac1f 0003 1b58 c2a0 592f c92b 3c40 0ef7  .....X..Y/.+<@..
	0x0020:  8018 00eb 5877 0000 0101 080a 0002 9b61  ....Xw.........a
	0x0030:  0002 9b61 242d 310d 0a3a 310d 0a3a 310d  ...a$-1..:1..:1.
	0x0040:  0a                                       .
```
