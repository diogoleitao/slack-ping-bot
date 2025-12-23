# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/version'

RSpec.describe SlackPingBot do
  describe '::VERSION' do
    it 'is defined' do
      expect(SlackPingBot::VERSION).not_to be_nil
    end

    it 'follows semantic versioning format' do
      expect(SlackPingBot::VERSION).to match(/^\d+\.\d+\.\d+$/)
    end
  end

  describe '::BUILD_SHA' do
    it 'is set from GIT_COMMIT_SHA or git command' do
      expect(SlackPingBot::BUILD_SHA).to match(/^[a-f0-9]{7}$/).or eq('unknown')
    end
  end

  describe '::BUILD_DATE' do
    it 'is set in UTC format' do
      expect(SlackPingBot::BUILD_DATE).to match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC$/)
    end
  end

  describe '.version_string' do
    it 'returns formatted version string' do
      expect(described_class.version_string).to match(/^v\d+\.\d+\.\d+ \(.+ @ .+\)$/)
    end

    it 'includes VERSION, BUILD_SHA, and BUILD_DATE' do
      version_string = described_class.version_string
      expect(version_string).to include(SlackPingBot::VERSION)
      expect(version_string).to include(SlackPingBot::BUILD_SHA)
      expect(version_string).to include(SlackPingBot::BUILD_DATE)
    end
  end
end
