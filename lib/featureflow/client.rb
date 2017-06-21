require 'logger'
require 'time'
require 'pp'
require 'featureflow/evaluate'
require 'featureflow/polling_client'

module Featureflow
  class Client
    def initialize(api_key, config = {})
      Featureflow.logger.info 'initializing client'
      @features = {}
      @config = {
        api_key: api_key,
        url: 'https://app.featureflow.io',
        path: '/api/sdk/v1/features',
        default_variants: {}
      }.merge(config)

      unless default_variants_valid? @config[:default_variants]
        raise ArgumentError, 'config[:default_variants] must be a Hash with string keys and string values'
      end

      PollingClient.new(@config[:url] + @config[:path],
                        @config[:api_key],
                        delay: 30,
                        timeout: 30) {|features| update_features(features)}

      Featureflow.logger.info 'client initialized'
    end

    def feature(key)
      @features[key]
    end

    def evaluate(key, context)
      raise ArgumentError, 'key must be a string' unless key.is_a?(String)
      raise ArgumentError, 'context is required (build with Featureflow::ContextBuilder)' unless context

      context = context.dup
      context[:values] = context[:values].merge('featureflow.key' => context[:key],
                                                'featureflow.date' => Time.now.iso8601)

      Evaluate.new key, feature(key), @config[:default_variants][key], context
    end

    private def update_features(features)
      Featureflow.logger.info "updating features"
      @features = features
    end

    private def default_variants_valid?(features)
      features.all? { |k, v| k.is_a?(String) && v.is_a?(String) }
    end
  end
end