require 'excon'
require 'featureflow'

# Step definitions for the shared testbed application-tag scenarios
# (testbed/gherkin/application_tag.feature) plus the Ruby-specific
# FEATUREFLOW_APPLICATION environment fallback scenario in features/ruby_client.feature.
#
# Outgoing requests are captured with excon's built-in mocking (Excon.stub with a
# block records each request's params) -- nothing touches the network. The capture
# endpoint gets its own host name so requests from this scenario's client can be
# told apart from any still-running background pollers left over from earlier
# scenarios; once the After hook switches mocking back off, those threads are
# talking to an unresolvable .test host and fail fast into the silenced logger.

CAPTURE_ENDPOINT = 'http://application-tag.capture.test'.freeze
CAPTURE_HOST = 'application-tag.capture.test'.freeze
FEATURES_PATH = '/api/sdk/v1/features'.freeze
REGISTER_PATH = '/api/sdk/v1/register'.freeze

def start_header_capture
  @captured_requests = captured = []
  Excon.defaults[:mock] = true
  Excon.stub({}) do |request|
    captured << request
    { status: 200, body: '{}', headers: {} }
  end
end

def capture_configuration_options(extra = {})
  test_configuration_options(endpoint: CAPTURE_ENDPOINT, event_endpoint: CAPTURE_ENDPOINT).merge(extra)
end

def captured_request(path)
  @captured_requests.find { |request| request[:host] == CAPTURE_HOST && request[:path] == path }
end

# Feature registration is sent from a background thread, so assertions poll briefly
# rather than assuming the request has already landed (as the Node SDK's steps do).
def eventually_captured(path, timeout: 2, interval: 0.02)
  deadline = Time.now + timeout
  loop do
    request = captured_request(path)
    return request if request
    raise "no request to #{path} was captured within #{timeout}s" if Time.now > deadline
    sleep interval
  end
end

# The application option falls back to ENV['FEATUREFLOW_APPLICATION'], so a value in
# the developer's shell would leak into the "no application" scenarios.
Before do
  @original_application_env = ENV.delete('FEATUREFLOW_APPLICATION') if ENV.key?('FEATUREFLOW_APPLICATION')
end

After do
  ENV['FEATUREFLOW_APPLICATION'] = @original_application_env if @original_application_env
  if Excon.defaults[:mock]
    Excon.stubs.clear
    Excon.defaults[:mock] = false
  end
end

Given(/^a features endpoint capturing request headers$/) do
  start_header_capture
end

Given(/^an events endpoint capturing request headers$/) do
  start_header_capture
end

Given(/^the environment variable FEATUREFLOW_APPLICATION is set to "([^"]*)"$/) do |value|
  ENV['FEATUREFLOW_APPLICATION'] = value
end

When(/^a client is initialised against it with application "([^"]*)"$/) do |application|
  @client = Featureflow::Client.new(capture_configuration_options(application: application))
end

When(/^a client is initialised against it with no application$/) do
  @client = Featureflow::Client.new(capture_configuration_options)
end

When(/^a client with a registered feature is initialised against it with application "([^"]*)"$/) do |application|
  @client = Featureflow::Client.new(capture_configuration_options(
    application: application,
    disable_events: false,
    with_features: [Featureflow::Feature.create('my-flag')]
  ))
end

Then(/^the captured features request has X-Featureflow-Application "([^"]*)"$/) do |expected|
  request = eventually_captured(FEATURES_PATH)
  expect(request[:headers]['X-Featureflow-Application']).to eq(expected)
end

Then(/^the captured features request has no X-Featureflow-Application header$/) do
  request = eventually_captured(FEATURES_PATH)
  expect(request[:headers]).not_to have_key('X-Featureflow-Application')
end

Then(/^the captured register request has X-Featureflow-Application "([^"]*)"$/) do |expected|
  request = eventually_captured(REGISTER_PATH)
  expect(request[:headers]['X-Featureflow-Application']).to eq(expected)
end
