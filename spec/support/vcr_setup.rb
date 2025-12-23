# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  config.filter_sensitive_data('<SLACK_BOT_TOKEN>') { ENV.fetch('SLACK_BOT_TOKEN', nil) }
  config.filter_sensitive_data('<SLACK_SIGNING_SECRET>') { ENV.fetch('SLACK_SIGNING_SECRET', nil) }

  config.ignore_localhost = true

  config.default_cassette_options = {
    record: :once,
    match_requests_on: %i[method uri body]
  }

  config.default_cassette_options[:record] = :new_episodes if ENV['VCR_RECORD']
end
