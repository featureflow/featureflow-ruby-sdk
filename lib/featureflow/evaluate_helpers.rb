require 'featureflow/conditions'
require 'digest/sha1'

module Featureflow
  class EvaluateHelpers
    def self.rule_matches(rule, user)
      if rule['defaultRule']
        true # the default rule will always match true
      else
        rule['audience']['conditions'].all? do |condition|
          user_values = user[:values][condition['target']]
          # convert to array to work with test
          Array(user_values).any? do |value|
            Conditions.test condition['operator'], value, condition['values']
          end
        end
      end
    end

    def self.get_variant_split_key(variant_splits, variant_value)
      percent = 0
      variant_splits.each do |variant_split|
        percent += variant_split['split']
        return variant_split['variantKey'] if percent >= variant_value
      end
    end

    def self.calculate_hash(salt = '1', feature = 'feature', key = 'anonymous')
      (Digest::SHA1.hexdigest [salt, feature, key].join(':'))[0..14];
    end

    def self.get_variant_value(hash)
      Integer(hash, 16) % 100 + 1
    end
  end
end