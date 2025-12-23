# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
end

ENV['RACK_ENV'] = 'test'
ENV['SLACK_BOT_TOKEN'] ||= 'xoxb-test-token-12345'
ENV['SLACK_SIGNING_SECRET'] ||= 'test-signing-secret-67890'
ENV['REDIS_URL'] ||= 'redis://localhost:6379/0'

require_relative '../app'
require 'rspec'
require 'rack/test'
require 'webmock/rspec'
require 'vcr'
require 'timecop'
require 'mock_redis'
require 'shoulda-matchers'

require_relative 'support/vcr_setup'
require_relative 'support/slack_helpers'
require_relative 'support/redis_helpers'

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include SlackHelpers
  config.include RedisHelpers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include(Shoulda::Matchers::Independent)

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = false

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  config.after do
    Timecop.return
  end
end

def load_fixture(name)
  file_path = File.join(__dir__, 'fixtures', "#{name}.json")
  JSON.parse(File.read(file_path), symbolize_names: true)
end
