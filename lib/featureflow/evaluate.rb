require_relative 'evaluate_helpers'

module Featureflow
  class Evaluate
    def initialize(feature_key, feature, default_variant = 'off', context = {})
      # Instance variables
      @evaluated_variant = calculate_variant feature_key, feature, default_variant, context
      @context = context
      @key = feature_key
    end

    def is?(value)
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

    private def calculate_variant(feature_key, feature, default_variant, context, salt = '1')
      return default_variant unless feature
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