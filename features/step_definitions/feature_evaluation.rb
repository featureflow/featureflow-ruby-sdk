require 'featureflow/evaluate'

Given(/^the feature "([^"]*)" with an offVariantKey "([^"]*)", a default key of "([^"]*)" is (enabled|disabled)$/) do |key, off_variant_key, default_key, enabled_or_disabled|
  @feature = {
    'key' => key,
    'offVariantKey' => off_variant_key,
    'enabled' => enabled_or_disabled == 'enabled',
    'rules' => [
      { 'defaultRule' => true, 'variantSplits' => [{ 'variantKey' => default_key, 'split' => 100 }] }
    ]
  }
end

When(/^the feature is evaluated with a user "([^"]*)"$/) do |user_id|
  evaluate = Featureflow::Evaluate.new(
    feature_key: @feature['key'],
    feature: @feature,
    failover_variant: nil,
    user: { id: user_id, attributes: {} },
    salt: '1'
  )
  @result = evaluate.value
end

Then(/^the evaluated variant should be "([^"]*)"$/) do |variant|
  expect(@result).to eq(variant)
end
