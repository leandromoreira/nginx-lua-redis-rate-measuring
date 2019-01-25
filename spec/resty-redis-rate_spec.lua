package.path = package.path .. ";spec/?.lua"

local redis_rate = require "resty-redis-rate"

describe("rate", function()
  it("todo", function()
    assert.same(1, 1)
  end)
end)
