require 'logger'
require 'time'
require 'pp'
require 'featureflow/evaluate'
require 'featureflow/polling_client'
require 'featureflow/events_client'

module Featureflow
  class Client
    def initialize(config = {})
      api_key = config[:api_key] || ENV['FEATUREFLOW_SERVER_KEY']
      raise ArgumentError, "You have not defined either config[:api_key] or ENV[:FEATUREFLOW_SERVER_KEY]" unless api_key
      Featureflow.logger.info 'initializing client'
      @features = {}
      @config = {
        api_key: api_key,
        url: 'https://app.featureflow.io',
        path: '/api/sdk/v1/features',
        with_features: [],
        disable_events: false
      }.merge(config)

      unless with_features_valid? @config[:with_features]
        raise ArgumentError, 'config[:with_features] must be an array of Feature hashes. Use Featureflow::Feature.create(key, failover_variant)'
      end

      @failover_variants = {}
      @config[:with_features].each do |feature|
        Featureflow.logger.info "Registering feature with key #{feature[:key]}"
        failover = feature[:failover_variant];
        @failover_variants[feature[:key]] = failover if failover.is_a?(String) && !failover.empty?
      end

      unless @config[:disable_events]
        @events_client = EventsClient.new @config[:url], @config[:api_key]
        @events_client.register_features @config[:with_features]
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
      raise ArgumentError, 'context is required' unless context
      unless context.is_a?(String) || context.is_a?(Hash)
        raise ArgumentError, 'context must be either a string context key,' + \
                             ' or a Hash built using Featureflow::ContextBuilder)'
      end

      context = ContextBuilder.new(context).build if context.is_a?(String)

      context = context.dup
      context[:values] = context[:values].merge('featureflow.key' => context[:key],
                                                'featureflow.date' => Time.now.iso8601)

      Evaluate.new key, feature(key), failover_variant(key), context, '1', @events_client
    end

    private def failover_variant(key)
      @failover_variants[key]
    end

    private def update_features(features)
      Featureflow.logger.info "updating features"
      @features = features
    end

    private def with_features_valid?(features)
      features.all? { |feature|
        feature[:key].is_a?(String) && feature[:failover_variant].is_a?(String) && feature[:variants].is_a?(Array)
      }
    end
  end
end