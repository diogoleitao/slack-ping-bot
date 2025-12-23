# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require_relative '../../app'

RSpec.describe 'Version Endpoint', type: :integration do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe 'GET /version' do
    it 'returns 200' do
      get '/version'
      expect(last_response.status).to eq(200)
    end

    it 'returns JSON' do
      get '/version'
      expect(last_response.content_type).to include('application/json')
    end

    it 'contains version information' do
      get '/version'
      json = JSON.parse(last_response.body)
      expect(json['version']).to eq(SlackPingBot::VERSION)
      expect(json['commit_sha']).to eq(SlackPingBot::BUILD_SHA)
      expect(json['build_date']).to eq(SlackPingBot::BUILD_DATE)
    end
  end
end
