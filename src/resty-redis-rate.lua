local redis_rate = {}

redis_rate.measure = function(redis_client, key)
  local current_time = math.floor(ngx.now())
  local current_minute = math.floor(current_time / 60) % 60
  local past_minute = current_minute - 1
  local current_key = key .. current_minute
  local past_key = key .. past_minute

  local resp, err = redis_client:get(past_key)
  if err then
    return nil, err
  end

  if resp == ngx.null then
    resp = "0"
  end

  local last_counter = tonumber(resp)

  resp, err = redis_client:incr(current_key)
  if err then
    return nil, err
  end

  local current_counter = tonumber(resp) - 1

  resp, err = redis_client:expire(current_key, 2 * 60)
  if err then
    return nil, err
  end

  -- strongly inspired by https://blog.cloudflare.com/counting-things-a-lot-of-different-things/
  local current_rate = last_counter * ((60 - (current_time % 60)) / 60) + current_counter
  return current_rate, nil
end

return redis_rate
