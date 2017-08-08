require 'featureflow/evaluate_helpers'

module Featureflow
  class Evaluate
    def initialize(feature_key:, feature:, failover_variant:, context:, salt:, events_client: nil)
      @key = feature_key
      @feature = feature
      @failover_variant = failover_variant
      @context = context
      @salt = salt
      @events_client = events_client

      @has_failover = @failover_variant.is_a?(String)
      @failover_variant = 'off' unless @has_failover

      @evaluated_variant = evaluate_variant
    end

    def is?(value)
      @events_client.evaluate(@key, @evaluated_variant, value, @context) if @events_client
      @evaluated_variant == value
    end

    def on?
      is? 'on'
    end
    alias is_on? on?

    def off?
      is? 'off'
    end
    alias is_off? off?

    def value
      @evaluated_variant
    end

    private

    def evaluate_variant
      unless @feature
        Featureflow.logger.info "Evaluating nil feature '#{@feature_key}' using the "\
          "#{@has_failover ? 'provided' : 'default'} failover '#{@failover_variant}'"
        return @failover_variant
      end

      return @feature['offVariantKey'] unless @feature['enabled']

      @feature['rules'].each do |rule|
        next unless EvaluateHelpers.rule_matches(rule, @context)
        hash = EvaluateHelpers.calculate_hash(@salt, @feature['key'], @context['key'])
        variant_value = EvaluateHelpers.get_variant_value(hash)
        return EvaluateHelpers.get_variant_split_key(rule['variantSplits'], variant_value)
      end
    end
  end
end
