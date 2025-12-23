# frozen_string_literal: true

module SlackPingBot
  VERSION = '0.1.0'

  BUILD_SHA = ENV.fetch('GIT_COMMIT_SHA',
                        begin
                          `git rev-parse --short HEAD 2>/dev/null`.strip
                        rescue StandardError
                          'unknown'
                        end)

  BUILD_DATE = ENV.fetch('BUILD_DATE', Time.now.utc.strftime('%Y-%m-%d %H:%M:%S UTC'))

  def self.version_string
    "v#{VERSION} (#{BUILD_SHA} @ #{BUILD_DATE})"
  end
end
