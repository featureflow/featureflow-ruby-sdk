require_relative 'evaluate_helpers'

module Featureflow
  class Evaluate
    def initialize(feature_key, feature, failover_variant, context, salt, events_client = nil)
      @evaluated_variant = calculate_variant feature_key, feature, failover_variant, context, salt
      @events_client = events_client
      @context = context
      @key = feature_key
    end

    def is?(value)
      @events_client.evaluate @key, @evaluated_variant, value, @context unless events_client.is_a?(NilClass)
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

    private def calculate_variant(feature_key, feature, failover_variant, context = {}, salt = '1')
      unless feature
        has_failover = failover_variant.is_a?(String)
        failover_variant = 'off' unless has_failover
        Featureflow.logger.info "Evaluating nil feature '#{feature_key}' using the "\
          "#{has_failover ? 'provided' : 'default'} failover '#{failover_variant}'"
        return failover_variant
      end

      return feature['offVariantKey'] unless feature['enabled']
      feature['rules'].each do |rule|
        next unless EvaluateHelpers.rule_matches rule, context
        hash = EvaluateHelpers.calculate_hash salt, feature['key'], context['key']
        variant_value = EvaluateHelpers.get_variant_value hash
        return EvaluateHelpers.get_variant_split_key rule['variantSplits'], variant_value
      end
    end
  end
end