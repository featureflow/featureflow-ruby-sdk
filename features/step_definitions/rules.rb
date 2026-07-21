require 'json'
require 'featureflow/evaluate_helpers'
require 'featureflow/user_builder'

Before do
  @rule = {
    'priority' => 0,
    'defaultRule' => false,
    'variantSplits' => []
  }
  @user_builder = Featureflow::UserBuilder.new('anonymous')
end

Given(/^the rule is a default rule$/) do
  @rule['defaultRule'] = true
end

When(/^the rule is matched against the user$/) do
  @result = Featureflow::EvaluateHelpers.rule_matches(@rule, @user_builder.build)
end

Then(/^the result from the match should be (true|false)$/) do |value|
  expect(@result.to_s).to eq(value)
end

Given(/^the user attributes are$/) do |user_attributes|
  user_attributes.hashes.each do |row|
    @user_builder.with_attributes row['key'] => JSON.parse(row['value'])
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
  @result = Featureflow::EvaluateHelpers.get_variant_split_key(
      @rule['variantSplits'],
      @variant_value
  )
end

Then(/^the resulting variant should be "([^"]*)"$/) do |result|
  expect(@result.to_s).to eq(result.to_s)
end