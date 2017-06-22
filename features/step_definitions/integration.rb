require 'featureflow'


Given(/^there is access to the Featureflow library$/) do
  expect(Featureflow::Client).to be
end

When(/^the FeatureflowClient is initialized with the apiKey "([^"]*)"$/) do |api_key|
  begin
    @client = Featureflow::Client.new api_key: api_key, disable_events: true
  rescue => e
    @error = e
  end
end

When(/^the FeatureflowClient is initialized with no apiKey$/) do
  begin
    @client = Featureflow::Client.new disable_events: true
  rescue => e
    @error = e
  end
end

When(/^the feature "([^"]*)" with context key "([^"]*)" is evaluated with the value "([^"]*)"$/) do |feature_key, context_key, value|
  @context = Featureflow::ContextBuilder.new(context_key).build
  @result = @client.evaluate(feature_key, @context).is? value
end


Then(/^it should return a featureflow client$/) do
  expect(@client).to be
end

Then(/^the featureflow client should throw an error$/) do
  expect(@error).to be
end

Then(/^the result of the evaluation should equal (true|false)$/) do |value|
  expect(@result).to eq(value == 'true')
end

And(/^it should be able to evaluate a rule$/) do
  expect(@client.evaluate(feature_key, context)).to be
end