package.path = package.path .. ";spec/?.lua"
-- Thu Jan 31 10:50:48 -02 2019
local FIXED_NOW = 1548939048
local ngx_now = FIXED_NOW
_G.ngx = {
  now=function()
    return ngx_now
  end,
  null="NULL"
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
    fake_redis.commit_pipeline = function(_)
      return {get_resp, incr_resp, expire_resp}, nil
    end
    ngx_now = FIXED_NOW
    expire_resp = "OK"
    get_resp = "0"
    incr_resp = "1"
end)

describe("Resty Redis Rate", function()
  it("returns the rate", function()
    -- Thu Jan 31 10:50:48 -02 2019
    get_resp = "10" -- last minute rate was 10 (1 each 6 seconds)
    incr_resp = "5" -- current rate counter is 5

    local resp, err = redis_rate.measure(fake_redis, "key")

    assert.is_nil(err)
    -- it takes partial contribution from the first counter (12/60)*10 plus current counter 4
    assert.same(6, resp)
  end)

  describe("When there is no past counter", function()
    it("returns rate for ongoing current counter", function()
      get_resp = ngx.null
      incr_resp = "10" -- this is your 10th hit but your rate is 9

      local resp, err = redis_rate.measure(fake_redis, "key")

      assert.is_nil(err)
      assert.same(9, resp)
    end)

    it("returns rate for starting current counter", function()
      get_resp = ngx.null
      incr_resp = "1" -- this is your first hit but your rate is 0

      local resp, err = redis_rate.measure(fake_redis, "key")

      assert.is_nil(err)
      assert.same(0, resp)
    end)
  end)

  it("returns an error when redis unavailable", function()
    fake_redis.commit_pipeline = function(_)
      return nil, "error"
    end

    local resp, err = redis_rate.measure(fake_redis, "key")

    assert.is_nil(resp)
    assert.is_not_nil(err)
  end)

  describe("Expiration time", function()
    it("decreases ttl based on time has passed", function()
      -- ngx.now() is Thu Jan 31 10:50:48 -02 2019 (1548939048)
      -- current second being 48 so we just subtract 48 seconds from 2 minutes
      local _ = redis_rate.measure(fake_redis, "key")

      assert.stub(fake_redis.expire).was_called_with(fake_redis, key_prefix .. "_{key}_50", 2 * 60 - 48)

      -- now we're simulating a second call after 10 seconds
      ngx_now = 1548939058

      _ = redis_rate.measure(fake_redis, "key")

      assert.stub(fake_redis.expire).was_called_with(fake_redis, key_prefix .. "_{key}_50", 2 * 60 - 58)
    end)

    it("works for the first second", function()
      -- $ date -r 1548939600
      -- Thu Jan 31 11:00:00 -02 2019
      ngx_now = 1548939600
      local _ = redis_rate.measure(fake_redis, "key")

      assert.stub(fake_redis.expire).was_called_with(fake_redis, key_prefix .. "_{key}_0", 2 * 60)
    end)

    it("works for the last second", function()
      -- $ date -r 1548939659
      -- Thu Jan 31 11:00:59 -02 2019
      ngx_now = 1548939659
      local _ = redis_rate.measure(fake_redis, "key")

      assert.stub(fake_redis.expire).was_called_with(fake_redis, key_prefix .. "_{key}_0", 2 * 60 - 59)
    end)
  end)

  it("works when minute wraps around", function()
    -- $ date -r 1548939600
    -- Thu Jan 31 11:00:00 -02 2019
    ngx_now = 1548939600

    local _ = redis_rate.measure(fake_redis, "key")

    assert.stub(fake_redis.get).was_called_with(fake_redis, key_prefix .. "_{key}_59")
  end)
end)
