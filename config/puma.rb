# frozen_string_literal: true

# Puma configuration for Ruby 3.4 with YJIT support
workers ENV.fetch("WEB_CONCURRENCY", 2)
threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
threads threads_count, threads_count

preload_app!

port ENV.fetch("PORT", 4567)
environment ENV.fetch("RACK_ENV", "production")

# Logging
stdout_redirect stdout: true, stderr: true, append: true

# Ruby 3.4 Performance Notes:
# - YJIT is enabled via RUBY_YJIT_ENABLE=1 environment variable
# - Expected performance improvement: 15-25% faster request handling
# - Memory overhead: ~40MB additional
# - YJIT stats available via RubyVM::YJIT.runtime_stats (if needed for monitoring)
