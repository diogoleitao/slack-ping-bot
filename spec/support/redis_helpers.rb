# frozen_string_literal: true

module RedisHelpers
  def mock_redis
    @mock_redis ||= MockRedis.new
  end

  def stub_redis_for(rate_limiter)
    allow(Redis).to receive(:new).and_return(mock_redis)
    rate_limiter.instance_variable_set(:@redis, mock_redis)
  end
end

RSpec.configure do |config|
  config.include RedisHelpers

  config.before do
    @mock_redis&.flushdb
  end
end
