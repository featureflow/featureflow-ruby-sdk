require 'featureflow'


Given(/^there is access to the Featureflow library$/) do
  expect(Featureflow::Client).to be
end

def build_client(api_key)
  config = Featureflow::Configuration.new
  config.api_key = api_key
  config.endpoint = ENV['FEATUREFLOW_TEST_BASE_URL'] if ENV['FEATUREFLOW_TEST_BASE_URL']
  config.event_endpoint = config.endpoint
  config.disable_events = true
  @client = Featureflow::Client.new(config)
rescue => e
  @error = e
end

# Reads the key from the environment rather than a literal in the .feature file, so
# no real SDK key is checked into source. Scenarios using this step are tagged
# @integration and excluded by default (see cucumber.yml) — they only run when a
# harness sets FEATUREFLOW_TEST_API_KEY.
When(/^the FeatureflowClient is initialized with the configured apiKey$/) do
  build_client(ENV['FEATUREFLOW_TEST_API_KEY'])
end

When(/^the FeatureflowClient is initialized with the apiKey "([^"]*)"$/) do |api_key|
  build_client(api_key)
end

When(/^the FeatureflowClient is initialized with no apiKey$/) do
  build_client(nil)
end

When(/^the feature "([^"]*)" with user id "([^"]*)" is evaluated with the value "([^"]*)"$/) do |feature_key, user_id, value|
  user = Featureflow::UserBuilder.new(user_id).build
  @result = @client.evaluate(feature_key, user).is? value
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