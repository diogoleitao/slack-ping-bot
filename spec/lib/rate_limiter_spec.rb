# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/rate_limiter'

RSpec.describe RateLimiter do
  let(:redis_url) { ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
  let(:logger) { instance_double(Ougai::Logger, warn: nil, info: nil, error: nil) }
  let(:user_id) { 'U123456' }

  describe '#check_and_increment' do
    context 'with Redis connection' do
      let(:rate_limiter) { described_class.new(redis_url, logger: logger) }

      before do
        stub_redis_for(rate_limiter)
      end

      it 'allows first ping' do
        expect(rate_limiter.check_and_increment(user_id)).to be true
      end

      it 'allows up to MAX_PINGS pings' do
        3.times do
          expect(rate_limiter.check_and_increment(user_id)).to be true
        end
      end

      it 'blocks ping after MAX_PINGS exceeded' do
        3.times { rate_limiter.check_and_increment(user_id) }

        expect(logger).to receive(:info).with(
          'Rate limit exceeded',
          user_id: user_id,
          limit: 3,
          window: '60s'
        )

        expect(rate_limiter.check_and_increment(user_id)).to be false
      end

      it 'resets count after window expires' do
        redis = mock_redis
        stub_redis_for(rate_limiter)

        3.times { rate_limiter.check_and_increment(user_id) }
        expect(rate_limiter.check_and_increment(user_id)).to be false

        redis.flushdb

        expect(rate_limiter.check_and_increment(user_id)).to be true
      end

      it 'tracks different users independently' do
        user2_id = 'U789ABC'

        3.times { rate_limiter.check_and_increment(user_id) }
        expect(rate_limiter.check_and_increment(user_id)).to be false

        expect(rate_limiter.check_and_increment(user2_id)).to be true
      end
    end

    context 'with Redis connection failure' do
      it 'falls back to in-memory storage' do
        test_logger = instance_double(Ougai::Logger)

        allow(Redis).to receive(:new).and_raise(Redis::CannotConnectError, 'Connection refused')

        expect(test_logger).to receive(:warn).with(
          'Redis connection failed, using in-memory fallback',
          hash_including(fallback_mode: 'in-memory')
        )

        described_class.new(redis_url, logger: test_logger)
      end

      it 'allows first ping in memory mode' do
        rate_limiter = described_class.new('redis://invalid:9999', logger: logger)
        expect(rate_limiter.check_and_increment(user_id)).to be true
      end

      it 'enforces rate limit in memory mode' do
        rate_limiter = described_class.new('redis://invalid:9999', logger: logger)
        3.times { rate_limiter.check_and_increment(user_id) }

        expect(logger).to receive(:info).with(
          'Rate limit exceeded (in-memory)',
          user_id: user_id,
          limit: 3,
          window: '60s'
        )

        expect(rate_limiter.check_and_increment(user_id)).to be false
      end

      it 'cleans up expired entries' do
        rate_limiter = described_class.new('redis://invalid:9999', logger: logger)

        Timecop.freeze(Time.now) do
          rate_limiter.check_and_increment(user_id)

          Timecop.travel(Time.now + 65) do
            expect(rate_limiter.check_and_increment(user_id)).to be true
          end
        end
      end
    end

    context 'with Redis error during operation' do
      let(:rate_limiter) { described_class.new(redis_url, logger: logger) }
      let(:redis) { mock_redis }

      before do
        stub_redis_for(rate_limiter)
      end

      it 'falls back to in-memory on Redis error' do
        allow(redis).to receive(:incr).and_raise(Redis::BaseError, 'Connection lost')

        expect(logger).to receive(:error).with(
          'Redis error, falling back to in-memory',
          error: 'Connection lost',
          fallback_mode: 'in-memory'
        )

        expect(rate_limiter.check_and_increment(user_id)).to be true
      end
    end
  end
end
