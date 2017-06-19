require 'json'
require_relative '../../lib/featureflow/ruby/src/EvaluateHelpers'

Before do
  @rule = {
    'priority' => 0,
    'defaultRule' => false,
    'variantSplits' => []
  }
  @context = {
    'key' => 'anonymous',
    'values' => {}
  }
end

Given(/^the rule is a default rule$/) do
  @rule['defaultRule'] = true
end

When(/^the rule is matched against the context$/) do
  @result = EvaluateHelpers.rule_matches(@rule, @context)
end

Then(/^the result from the match should be (true|false)$/) do |value|
  expect(@result.to_s).to eq(value)
end

Given(/^the context values are$/) do |context_values|
  context_values.hashes.each do |row|
    @context['values'][row['key']] = JSON.parse(row['value'])
  end
end

Given(/^the rule's audience conditions are$/) do |conditions|
  @rule['audience'] = {
    'conditions' => []
  }
  conditions.hashes.each do |condition|
    cond = {
      'operator' => condition['operator'],
      'target' => condition['target'],
      'values' => JSON.parse(condition['values'])
    }
    @rule['audience']['conditions'].push cond
  end

end

Given(/^the variant value of (\d+)$/) do |value|
  @variant_value = value.to_i
end

Given(/^the variant splits are$/) do |splits|
  splits.hashes.each do |split|
    other_split = {
      'variantKey' => split['variantKey'],
      'split' => split['split'].to_i
    }
    @rule['variantSplits'].push other_split
  end
end

When(/^the variant split key is calculated$/) do
  @result = EvaluateHelpers.get_variant_split_key(@rule['variantSplits'], @variant_value)
end

Then(/^the resulting variant should be "([^']*)"$/) do |result|
  expect(@result.to_s).to eq(result.to_s)
end