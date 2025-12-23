# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/slack_verifier'
require 'rack'
require 'timecop'

RSpec.describe SlackVerifier do
  let(:signing_secret) { 'test-signing-secret' }
  let(:timestamp) { Time.now.to_i.to_s }
  let(:body) { 'token=xoxb-test&team_id=T123&text=@user' }
  let(:logger) { instance_double(Ougai::Logger, warn: nil) }

  let(:sig_basestring) { "v0:#{timestamp}:#{body}" }
  let(:valid_signature) do
    "v0=#{OpenSSL::HMAC.hexdigest("SHA256", signing_secret, sig_basestring)}"
  end

  let(:request) do
    env = {
      'HTTP_X_SLACK_REQUEST_TIMESTAMP' => timestamp,
      'HTTP_X_SLACK_SIGNATURE' => valid_signature,
      'rack.input' => StringIO.new(body)
    }
    Rack::Request.new(env)
  end

  describe '.valid?' do
    context 'with valid signature and timestamp' do
      it 'returns true' do
        expect(described_class.valid?(request, signing_secret, logger: logger)).to be true
      end
    end

    context 'with invalid signature' do
      it 'returns false' do
        request.env['HTTP_X_SLACK_SIGNATURE'] = 'v0=invalid_signature'
        expect(described_class.valid?(request, signing_secret, logger: logger)).to be false
      end
    end

    context 'with missing timestamp header' do
      it 'returns false' do
        request.env['HTTP_X_SLACK_REQUEST_TIMESTAMP'] = nil
        expect(described_class.valid?(request, signing_secret, logger: logger)).to be false
      end
    end

    context 'with missing signature header' do
      it 'returns false' do
        request.env['HTTP_X_SLACK_SIGNATURE'] = nil
        expect(described_class.valid?(request, signing_secret, logger: logger)).to be false
      end
    end

    context 'with expired timestamp' do
      it 'returns false and logs warning' do
        old_timestamp = (Time.now.to_i - 400).to_s
        request.env['HTTP_X_SLACK_REQUEST_TIMESTAMP'] = old_timestamp

        sig_basestring = "v0:#{old_timestamp}:#{body}"
        old_signature = "v0=#{OpenSSL::HMAC.hexdigest("SHA256", signing_secret, sig_basestring)}"
        request.env['HTTP_X_SLACK_SIGNATURE'] = old_signature

        expect(logger).to receive(:warn).with(
          'Request timestamp too old',
          timestamp: old_timestamp,
          max_age: '300s'
        )

        expect(described_class.valid?(request, signing_secret, logger: logger)).to be false
      end
    end

    context 'with timestamp exactly at limit' do
      it 'returns true' do
        limit_timestamp = (Time.now.to_i - 300).to_s
        request.env['HTTP_X_SLACK_REQUEST_TIMESTAMP'] = limit_timestamp

        sig_basestring = "v0:#{limit_timestamp}:#{body}"
        limit_signature = "v0=#{OpenSSL::HMAC.hexdigest("SHA256", signing_secret, sig_basestring)}"
        request.env['HTTP_X_SLACK_SIGNATURE'] = limit_signature

        expect(described_class.valid?(request, signing_secret, logger: logger)).to be true
      end
    end
  end

  describe '.secure_compare' do
    context 'with matching strings' do
      it 'returns true' do
        expect(described_class.secure_compare('hello', 'hello')).to be true
      end
    end

    context 'with different strings of same length' do
      it 'returns false' do
        expect(described_class.secure_compare('hello', 'world')).to be false
      end
    end

    context 'with strings of different lengths' do
      it 'returns false' do
        expect(described_class.secure_compare('hello', 'hello world')).to be false
        expect(described_class.secure_compare('hello world', 'hello')).to be false
      end
    end

    context 'with empty strings' do
      it 'returns true' do
        expect(described_class.secure_compare('', '')).to be true
      end
    end
  end
end
