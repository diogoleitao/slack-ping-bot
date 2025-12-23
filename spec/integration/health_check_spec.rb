# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require_relative '../../app'

RSpec.describe 'Health Check Endpoint', type: :integration do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe 'GET /' do
    it 'returns 200' do
      get '/'
      expect(last_response.status).to eq(200)
    end

    it 'returns JSON' do
      get '/'
      expect(last_response.content_type).to include('application/json')
    end

    it 'contains status and service name' do
      get '/'
      json = JSON.parse(last_response.body)
      expect(json['status']).to eq('ok')
      expect(json['service']).to eq('slack-ping-bot')
    end
  end
end
