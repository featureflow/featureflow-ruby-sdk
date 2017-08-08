require 'featureflow/evaluate'
require 'featureflow/polling_client'
require 'featureflow/events_client'

module Featureflow
  class Client
    def initialize(configuration = nil)
      @configuration = configuration || Featureflow.configuration
      @configuration.validate!
      @features = {}

      Featureflow.logger.info 'initializing client'

      @failover_variants = {}
      @configuration.with_features.each do |feature|
        Featureflow.logger.info "Registering feature with key #{feature[:key]}"
        failover = feature[:failover_variant];
        @failover_variants[feature[:key]] = failover if failover.is_a?(String) && !failover.empty?
      end

      unless @configuration.disable_events
        @events_client = EventsClient.new @configuration.endpoint, @configuration.api_key
        @events_client.register_features @configuration.with_features
      end

      PollingClient.new(
        @configuration.endpoint,
        @configuration.api_key,
        poll_interval: 10,
        timeout: 30
      ) do |features|
        update_features(features)
      end

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

    private
    def failover_variant(key)
      @failover_variants[key]
    end

    def update_features(features)
      Featureflow.logger.info "updating features"
      @features = features
    end
  end
end