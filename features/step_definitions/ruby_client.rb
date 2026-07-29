require 'featureflow'

When(/^a client is created with a Hash of configuration options$/) do
  begin
    @client = Featureflow::Client.new(test_configuration_options)
  rescue => e
    @error = e
  end
end

When(/^a client is created with an explicit Configuration$/) do
  config = Featureflow::Configuration.new
  test_configuration_options.each { |option, value| config.send("#{option}=", value) }
  begin
    @client = Featureflow::Client.new(config)
  rescue => e
    @error = e
  end
end

When(/^a client is created with an unknown configuration option$/) do
  begin
    @client = Featureflow::Client.new(test_configuration_options(not_a_real_option: true))
  rescue => e
    @error = e
  end
end

Given(/^the environment variable FEATUREFLOW_SERVER_KEY is set$/) do
  @env_server_key = 'sdk-srv-env-11111111111111111111111111111111'
  @original_server_key = ENV['FEATUREFLOW_SERVER_KEY']
  ENV['FEATUREFLOW_SERVER_KEY'] = @env_server_key
  # Configuration reads the environment in its constructor, so the memoised
  # process-wide instance has to go for the new value to be picked up.
  Featureflow.instance_variable_set(:@configuration, nil)
  Featureflow.configure(test_configuration_options.reject { |option, _| option == :api_key })
end

When(/^a client is created with no arguments$/) do
  begin
    @client = Featureflow::Client.new
  rescue => e
    @error = e
  end
end

Then(/^a client should be returned without an error$/) do
  expect(@error).to be_nil
  expect(@client).to be
end

Then(/^the client configuration should use the server key from the environment$/) do
  expect(Featureflow.configuration.api_key).to eq(@env_server_key)
end

Given(/^the featureflow client is configured against an unreachable endpoint$/) do
  Featureflow.instance_variable_set(:@configuration, nil)
  Featureflow.configure(test_configuration_options)
  @recording_client = RecordingClient.new(Featureflow::Client.new)
  Featureflow.instance_variable_set(:@client, @recording_client)
end

Given(/^a rails request from ip "([^"]*)" with url "([^"]*)"$/) do |ip, url|
  @rails_client = Featureflow::RailsClient.new(FakeRailsRequest.new(ip, url))
end

When(/^the rails helper evaluates "([^"]*)" for the user id "([^"]*)"$/) do |key, user_id|
  begin
    @result = @rails_client.evaluate(key, user_id)
  rescue => e
    @error = e
  end
end

RAILS_EVALUATE_WITH_ATTRIBUTE =
  /^the rails helper evaluates "([^"]*)" for the user id "([^"]*)" with attribute "([^"]*)" of "([^"]*)"$/

When(RAILS_EVALUATE_WITH_ATTRIBUTE) do |key, user_id, attribute, value|
  user = Featureflow::UserBuilder.new(user_id).with_attributes(attribute => value).build
  begin
    @result = @rails_client.evaluate(key, user)
  rescue => e
    @error = e
  end
end

Then(/^the rails helper should not raise an error$/) do
  expect(@error).to be_nil
  expect(@result).to be
end

Then(/^the evaluated user should have the id "([^"]*)"$/) do |id|
  expect(@recording_client.last_user[:id]).to eq(id)
end

Then(/^the evaluated user should have the attribute "([^"]*)" with value "([^"]*)"$/) do |key, value|
  expect(@recording_client.last_user[:attributes][key].to_s).to eq(value)
end
