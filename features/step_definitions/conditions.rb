require_relative '../../lib/featureflow/ruby/src/Conditions'

Given(/^the target is a "([^"]*)" with the value of "([^"]*)"$/) do |type, target|
  @result = nil
  @target = type == 'number' ? Float(target) : target
end

Given(/^the value is a "([^"]*)" with the value of "([^"]*)"$/) do |type, value|
  @result = nil
  @value = type == 'number' ? Float(value) : value
  @value = [@value]
end

When(/^the operator test "([^"]*)" is run$/) do |op|
  @result = Conditions.test(op, @target, @value)
end

Then(/^the output should equal "([^"]*)"$/) do |result|
  expect(@result.to_s).to eq(result.to_s)
end

Given(/^the value is an array of values "([^"]*)"$/) do |values|
  @value = values.split(', ')
end