require 'excon'
require 'json'

module Featureflow
  class PollingClient
    DEFAULT_OPTIONS = {
      poll_interval: 30,
      timeout: 30
    }.freeze
    def initialize(url, api_key, options = {}, &set_features)
      @etag = ''
      @url = url
      @api_key = api_key
      @options = DEFAULT_OPTIONS.merge(options)
      @set_features = set_features

      load_features
      Thread.new do
        loop do
          sleep @options[:poll_interval]
          load_features
        end
      end
    end

    def load_features
      response = Excon.get(@url, headers: {
        'Authorization' => "Bearer #{@api_key}",
        'If-None-Match' => @etag
      }, omit_default_port: true, read_timeout: @options[:timeout])
      if response.status == 200
        @etag = response.headers['ETag']
        @set_features.call(JSON.parse(response.body))
      elsif response.status >= 400
        Featureflow.logger.error "request for features failed with response status #{response.status}"
        Featureflow.logger.error response.to_s
      end
    rescue => e
      Featureflow.logger.error e.inspect
    end
  end
end