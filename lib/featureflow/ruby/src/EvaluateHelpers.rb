require_relative 'Conditions'
require 'digest/sha1'


class EvaluateHelpers
  def self.rule_matches(rule, context)
    if rule['defaultRule']
      true # the default rule will always match true
    else
      rule['audience']['conditions'].each do |condition|
        test_result = false
        context_values = context['values'][condition['target']]

        # convert to array to work with test
        context_values = [context_values] unless context_values.is_a? Array

        context_values.each do |value|
          test_result = true if Conditions.test condition['operator'], value, condition['values']
        end
        return false unless test_result
      end
      true # all tests pass, return true
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