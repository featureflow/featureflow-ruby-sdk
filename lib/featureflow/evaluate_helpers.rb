require 'featureflow/conditions'
require 'digest/sha1'

module Featureflow
  class EvaluateHelpers
    def self.rule_matches(rule, user)
      if rule['defaultRule']
        true # the default rule will always match true
      else
        rule['audience']['conditions'].all? do |condition|
          user_attributes = user[:attributes][condition['target']]
          # convert to array to work with test
          Array(user_attributes).any? do |attribute|
            Conditions.test condition['operator'], attribute, condition['values']
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