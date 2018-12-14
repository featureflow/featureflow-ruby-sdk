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

    def evaluate(key, user)
      raise ArgumentError, 'key must be a string' unless key.is_a?(String)
      raise ArgumentError, 'user is required' unless user
      unless user.is_a?(String) || user.is_a?(Hash)
        raise ArgumentError, 'user must be either a string user id,' + \
                             ' or a Hash built using Featureflow::UserBuilder)'
      end

      user = UserBuilder.new(user).build if user.is_a?(String)

      user = user.dup
      user[:attributes] = user[:attributes].merge('featureflow.user.id' => user[:id])

      Evaluate.new(
        feature_key: key,
        feature: feature(key),
        failover_variant: failover_variant(key),
        user: user,
        salt: '1',
        events_client: @events_client
      )
    end
  end
end