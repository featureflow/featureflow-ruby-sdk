require 'time'
require 'featureflow/application'
require 'featureflow/evaluate'
require 'featureflow/polling_client'
require 'featureflow/events_client'

module Featureflow
  class Client
    def initialize(configuration = nil)
      @configuration = build_configuration(configuration)
      @configuration.validate!
      @features = {}

      # Optional workload name sent as X-Featureflow-Application on every request so
      # usage and flag evaluations are attributable per application in the dashboard.
      @application = Application.sanitise(@configuration.application)

      Featureflow.logger.info 'initializing client'

      @failover_variants = {}
      @configuration.with_features.each do |feature|
        Featureflow.logger.info "Registering feature with key #{feature[:key]}"
        failover = feature[:failover_variant];
        @failover_variants[feature[:key]] = failover if failover.is_a?(String) && !failover.empty?
      end

      unless @configuration.disable_events
        @events_client = EventsClient.new @configuration.event_endpoint, @configuration.api_key, @application
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
        timeout: 30,
        application: @application
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
      # Implicit attributes injected at evaluation time (matching the Node SDK's
      # EvaluateHelpers): featureflow.date/hourofday let rules target the current
      # moment; sdk-server's partial evaluation defers these to the JS client, but
      # server SDKs evaluate them locally against "now".
      now = Time.now
      user[:attributes] = user[:attributes].merge(
        'featureflow.user.id' => user[:id],
        'featureflow.date' => now.utc.iso8601,
        'featureflow.hourofday' => now.hour
      )

      Evaluate.new(
        feature_key: key,
        feature: feature(key),
        failover_variant: failover_variant(key),
        user: user,
        salt: '1',
        events_client: @events_client
      )
    end

    # Accepts either a Featureflow::Configuration, or a Hash of configuration
    # options — `Featureflow::Client.new(api_key: '...')` is the form the README
    # leads with and the natural Ruby idiom. Passing nothing keeps using the
    # process-wide Featureflow.configuration (which reads FEATUREFLOW_SERVER_KEY).
    private def build_configuration(configuration)
      return Featureflow.configuration if configuration.nil?
      return configuration unless configuration.is_a?(Hash)

      config = Configuration.new
      configuration.each do |option, value|
        setter = "#{option}="
        # Fail loudly rather than silently dropping a mistyped option — a
        # misspelt `endpoint:` would otherwise quietly poll production.
        unless config.respond_to?(setter)
          raise ArgumentError, "Unknown Featureflow configuration option: #{option}"
        end
        config.public_send(setter, value)
      end
      config
    end
  end
end