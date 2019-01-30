package = "resty-redis-rate"
version = "1.0.0-0"
source = {
  url = "github.com/leandromoreira/nginx-lua-redis-rate-measuring",
  tag = "1.0.0"
}
description = {
  summary = "A resty Lua library to provide distributed rate measurement using Redis",
  homepage = "https://github.com/leandromoreira/nginx-lua-redis-rate-measuring",
  license = "BSD 3-Clause"
}
dependencies = {
  "lua-resty-redis",
  "lua-resty-lock"
  -- it also depends on resty-redis-cluster
  -- please see https://github.com/leandromoreira/nginx-lua-redis-rate-measuring/blob/master/Dockerfile
}
build = {
  type = "builtin",
  modules = {
    ["resty-redis-rate"] = "src/resty-redis-rate.lua"
  }
}
