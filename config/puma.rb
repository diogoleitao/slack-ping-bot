# frozen_string_literal: true

workers ENV.fetch('WEB_CONCURRENCY', 2)
threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
threads threads_count, threads_count

preload_app!

port ENV.fetch('PORT', 4567)
environment ENV.fetch('RACK_ENV', 'production')

stdout_redirect stdout: true, stderr: true, append: true
