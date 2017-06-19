require_relative '../../lib/featureflow/ruby/src/EvaluateHelpers'

Given(/^the salt is "([^"]*)", the feature is "([^"]*)" and the key is "([^"]*)"$/) do |salt, feature, key|
  @salt = salt
  @feature = feature
  @key = key
end

When(/^the variant value is calculated$/) do
  @hash = EvaluateHelpers.calculateHash(@salt, @feature, @key);
  @result = EvaluateHelpers.getVariantValue(@hash);
end

Then(/^the hash value calculated should equal "([^"]*)"$/) do |hash|
  expect(@hash.to_s).to eq(hash.to_s)
end

Then(/^the result from the variant calculation should be (\d+)$/) do |result|
  expect(@result.to_s).to eq(result.to_s)
end