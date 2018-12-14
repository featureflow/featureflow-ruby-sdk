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
        @events_client = EventsClient.new @configuration.event_endpoint, @configuration.api_key
        @events_client.register_features @configuration.with_features
      end

      reload

      Featureflow.logger.info 'client initialized'
    end

    def reload
      @polling_client.finish if @polling_client
      @polling_client = build_polling_client
    end

    def build_polling_client
      PollingClient.new(
        @configuration.endpoint,
        @configuration.api_key,
        poll_interval: 10,
        timeout: 30
      )
    end

    def feature(key)
      @polling_client.feature(key)
    end

    def failover_variant(key)
      @failover_variants[key]
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
      context[:values] = context[:values].merge('featureflow.key' => context[:key])

      Evaluate.new(
        feature_key: key,
        feature: feature(key),
        failover_variant: failover_variant(key),
        context: context,
        salt: '1',
        events_client: @events_client
      )
    end
  end
end