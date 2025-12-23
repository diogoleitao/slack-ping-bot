# frozen_string_literal: true

require 'redis'
require 'ougai'

class RateLimiter
  MAX_PINGS = 3
  WINDOW_SECONDS = 60

  def initialize(redis_url, logger: Ougai::Logger.new($stdout))
    @logger = logger
    @redis = connect_redis(redis_url)
    @fallback = {}
    @mutex = Mutex.new
  end

  def check_and_increment(user_id)
    if @redis
      check_redis(user_id)
    else
      check_memory(user_id)
    end
  end

  private

  def connect_redis(redis_url)
    Redis.new(url: redis_url)
  rescue Redis::CannotConnectError => e
    @logger.warn('Redis connection failed, using in-memory fallback', error: e.message, fallback_mode: 'in-memory')
    nil
  end

  def check_redis(user_id)
    key = "ping:limit:#{user_id}"

    count = @redis.incr(key)
    @redis.expire(key, WINDOW_SECONDS) if count == 1

    if count > MAX_PINGS
      @logger.info('Rate limit exceeded', user_id: user_id, limit: MAX_PINGS, window: "#{WINDOW_SECONDS}s")
      return false
    end

    true
  rescue Redis::BaseError => e
    @logger.error('Redis error, falling back to in-memory', error: e.message, fallback_mode: 'in-memory')
    @redis = nil
    check_memory(user_id)
  end

  def check_memory(user_id)
    @mutex.synchronize do
      now = Time.now
      @fallback.delete_if { |_, data| data[:expires_at] < now }

      user_data = @fallback[user_id]

      if user_data.nil?
        @fallback[user_id] = {
          count: 1,
          expires_at: now + WINDOW_SECONDS
        }
        return true
      end

      if user_data[:expires_at] < now
        @fallback[user_id] = {
          count: 1,
          expires_at: now + WINDOW_SECONDS
        }
        return true
      end

      user_data[:count] += 1

      if user_data[:count] > MAX_PINGS
        @logger.info('Rate limit exceeded (in-memory)', user_id: user_id, limit: MAX_PINGS,
                                                        window: "#{WINDOW_SECONDS}s")
        return false
      end

      true
    end
  end
end
