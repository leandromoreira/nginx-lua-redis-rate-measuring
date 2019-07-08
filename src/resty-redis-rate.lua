local redis_rate = {}

local key_prefix = "ngx_rate_measuring"
local math_floor = math.floor
local ngx_now = ngx.now
local ngx_null = ngx.null
local tonumber = tonumber

redis_rate.measure = function(redis_client, key)
  local current_time = math_floor(ngx_now())
  local current_second = current_time % 60
  local current_minute = math_floor(current_time / 60) % 60
  local past_minute = (current_minute + 59) % 60
  local current_key = key_prefix .. "_{" .. key .. "}_" .. current_minute
  local past_key = key_prefix .. "_{" .. key .. "}_" .. past_minute

  redis_client:init_pipeline()

  redis_client:get(past_key)
  redis_client:incr(current_key)
  redis_client:expire(current_key, 2 * 60 - current_second)

  local resp, err = redis_client:commit_pipeline()
  if err then
    return nil, err
  end

  local first_resp = resp[1]
  if first_resp == ngx_null then
    first_resp  = "0"
  end
  local past_counter = tonumber(first_resp)
  local current_counter = tonumber(resp[2]) - 1

  -- strongly inspired by https://blog.cloudflare.com/counting-things-a-lot-of-different-things/
  local current_rate = past_counter * ((60 - (current_time % 60)) / 60) + current_counter
  return current_rate, nil
end

return redis_rate
