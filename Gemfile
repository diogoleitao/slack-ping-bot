# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 3.4.0'

gem 'puma', '~> 7.1'
gem 'sinatra', '~> 4.2'

gem 'slack-ruby-client', '~> 3.1'

gem 'redis', '~> 5.4'

gem 'dotenv', '~> 3.2'

gem 'ougai', '~> 2.0'

group :test do
  gem 'mock_redis', '~> 0.44'
  gem 'rack-test', '~> 2.1'
  gem 'rspec', '~> 3.13'
  gem 'shoulda-matchers', '~> 6.4'
  gem 'simplecov', '~> 0.22', require: false
  gem 'timecop', '~> 0.9'
  gem 'vcr', '~> 6.3'
  gem 'webmock', '~> 3.20'
end

group :development, :test do
  gem 'pry', '~> 0.15'
end

group :development do
  gem 'rerun', '~> 0.14'

  gem 'rubocop', '~> 1.70', require: false
  gem 'rubocop-performance', '~> 1.23', require: false
  gem 'rubocop-rake', '~> 0.6', require: false
  gem 'rubocop-rspec', '~> 3.8', require: false
end
