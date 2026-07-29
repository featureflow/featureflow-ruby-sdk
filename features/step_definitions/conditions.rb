require 'featureflow/conditions'

Given(/^the target is a "([^"]*)" with the value of "([^"]*)"$/) do |type, target|
  @result = nil
  @target = type == 'number' ? Float(target) : target
end

Given(/^the attribute is a "([^"]*)" with the value of "([^"]*)"$/) do |type, value|
  @result = nil
  @value = type == 'number' ? Float(value) : value
  @value = [@value]
end

When(/^the operator test "([^"]*)" is run$/) do |op|
  @result = Featureflow::Conditions.test(op, @target, @value)
end

Then(/^the output should equal "([^"]*)"$/) do |result|
  expect(@result.to_s).to eq(result.to_s)
end

Given(/^the attribute is an array of values "([^"]*)"$/) do |values|
  @value = values.split(', ')
end

# Parsing a zoneless date in the process's local timezone was the bug these scenarios
# guard, so they run under an explicit — and mostly non-UTC — TZ.
Given(/^the host timezone is "([^"]*)"$/) do |timezone|
  @original_tz = ENV['TZ']
  ENV['TZ'] = timezone
end

When(/^the date value "([^"]*)" is parsed$/) do |value|
  @epoch = Featureflow::Conditions.to_epoch(value)
end

Then(/^the parsed instant should be "([^"]*)"$/) do |instant|
  expect(@epoch).to be
  expect(Time.at(@epoch).utc.iso8601).to eq(instant)
end