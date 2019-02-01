package.path = package.path .. ";spec/?.lua"
-- Thu Jan 31 10:50:48 -02 2019
local FIXED_NOW = 1548939048
local ngx_now = FIXED_NOW
_G.ngx = {
  now=function()
    return ngx_now
  end
}

local redis_rate = require "resty-redis-rate"

local key_prefix = "ngx_rate_measuring"
local fake_redis
local expire_resp = "OK"
local get_resp = "0"
local incr_resp = "1"

before_each(function()
    fake_redis = {}
    stub(fake_redis, "init_pipeline")
    stub(fake_redis, "get")
    stub(fake_redis, "incr")
    stub(fake_redis, "expire")
    fake_redis.commit_pipeline = function(self)
      return {get_resp, incr_resp, expire_resp}
    end
    ngx_now = FIXED_NOW
end)

describe("Resty Redis Rate", function()
  describe("Expiration time", function()
    it("decreases ttl based on time has passed", function()
      -- ngx.now() is Thu Jan 31 10:50:48 -02 2019 (1548939048)
      -- current second being 48 so we just subtract 48 seconds from 2 minutes
      local rate = redis_rate.measure(fake_redis, "key")

      assert.stub(fake_redis.expire).was_called_with(fake_redis, key_prefix .. "_{key}_50", 2 * 60 - 48)
    end)

    it("works for the first second", function()
      -- $ date -r 1548939600
      -- Thu Jan 31 11:00:00 -02 2019
      ngx_now = 1548939600
      local rate = redis_rate.measure(fake_redis, "key")

      assert.stub(fake_redis.expire).was_called_with(fake_redis, key_prefix .. "_{key}_0", 2 * 60)
    end)

    it("works for the last second", function()
      -- $ date -r 1548939659
      -- Thu Jan 31 11:00:59 -02 2019
      ngx_now = 1548939659
      local rate = redis_rate.measure(fake_redis, "key")

      assert.stub(fake_redis.expire).was_called_with(fake_redis, key_prefix .. "_{key}_0", 2 * 60 - 59)
    end)
  end)

  it("works when minute wraps around", function()
    -- $ date -r 1548939600
    -- Thu Jan 31 11:00:00 -02 2019
    ngx_now = 1548939600

    local rate = redis_rate.measure(fake_redis, "key")

    assert.stub(fake_redis.get).was_called_with(fake_redis, key_prefix .. "_{key}_59")
  end)
end)
