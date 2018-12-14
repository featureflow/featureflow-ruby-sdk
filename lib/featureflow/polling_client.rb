require 'excon'
require 'json'

module Featureflow
  class PollingClient
    DEFAULT_OPTIONS = {
      poll_interval: 30,
      timeout: 30
    }.freeze
    LOCK = Mutex.new

    def initialize(url, api_key, options = {})
      @etag = ''
      @url = url
      @api_key = api_key
      @options = DEFAULT_OPTIONS.merge(options)
      @features = {}

      load_features

      @thread = Thread.new do
        loop do
          sleep @options[:poll_interval]
          load_features
        end
      end
    end

    def finish
      @thread.exit
    end

    def feature(key)
      LOCK.synchronize { @features[key] }
    end

    def load_features
      response = Excon.get(@url +  + '/api/sdk/v1/features', headers: {
        'Authorization' => "Bearer #{@api_key}",
        'Accept' => 'Application/Json',
        'If-None-Match' => @etag,
        'X-Featureflow-Client' => 'RubyClient/' + Featureflow::VERSION
      }, omit_default_port: true, read_timeout: @options[:timeout])

      if response.status == 200
        Featureflow.logger.debug "updating features"

        @etag = response.headers['ETag']

        features = JSON.parse(response.body)

        LOCK.synchronize { @features = features }
      elsif response.status >= 400
        Featureflow.logger.error "request for features failed with response status #{response.status}"
        Featureflow.logger.error response.to_s
      end
    rescue => e
      Featureflow.logger.error e.inspect
    end
  end
end