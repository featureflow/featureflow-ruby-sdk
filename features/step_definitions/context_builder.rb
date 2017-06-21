require "featureflow"

Given(/^there is access to the Context Builder module$/) do
  expect(Featureflow::ContextBuilder).to be
end

When(/^the builder is initialised with the key "([^"]*)"$/) do |key|
  begin
    @builder = Featureflow::ContextBuilder.new(key)
  rescue => e
    @error = e
  end
end

And(/^the context is built using the builder$/) do
  @context = @builder.build
end

Then(/^the result context should have a key "([^"]*)"$/) do |key|
  expect(@context[:key]).to eq(key)
end


And(/^the builder is given the following values$/) do |values|
  hashes = {}
  values.hashes.each do |hash|
    hashes[hash['key']] = hash['value']
  end
  @builder.with_values(hashes)
end

And(/^the result context should have the key "([^"]*)" with value "([^"]*)"$/) do |key, value|
  expect(@context[:values][key]).to eq(value)
end

And(/^the result context should have no values$/) do
  expect(@context[:values].keys.length).to eq(0)
end

Then(/^the builder should throw an error$/) do
  expect(@error).to be
end