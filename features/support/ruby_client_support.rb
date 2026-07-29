require 'logger'
require 'featureflow'
# The Railtie only loads under Rails, so the controller helper is required directly.
require 'featureflow/rails/rails_client'

# Nothing here should touch the network: pointing the client at a closed port makes
# the initial (and polled) feature load fail fast, so every feature falls back to
# its failover variant.
UNREACHABLE_ENDPOINT = 'http://127.0.0.1:1'.freeze
TEST_API_KEY = 'sdk-srv-env-00000000000000000000000000000000'.freeze

# Stands in for an ActionDispatch::Request — RailsClient only reads these two.
FakeRailsRequest = Struct.new(:remote_ip, :original_url)

# Wraps the real client so scenarios can assert on exactly what RailsClient hands
# to Client#evaluate, without stubbing the evaluation itself out.
class RecordingClient
  attr_reader :last_user

  def initialize(client)
    @client = client
  end

  def evaluate(key, user)
    @last_user = user
    @client.evaluate(key, user)
  end
end

def test_configuration_options(extra = {})
  {
    api_key: TEST_API_KEY,
    endpoint: UNREACHABLE_ENDPOINT,
    event_endpoint: UNREACHABLE_ENDPOINT,
    disable_events: true,
    logger: Logger.new(IO::NULL)
  }.merge(extra)
end

# Featureflow.configuration/.client are process-wide singletons; drop them so one
# scenario's configuration cannot leak into the next.
# Featureflow.logger reads the process-wide configuration rather than the client's
# own, so silence that as well — otherwise the unreachable endpoint makes
# PollingClient log a connection error over the cucumber output.
Before do
  Featureflow.configuration.logger = Logger.new(IO::NULL)
end

After do
  Featureflow.instance_variable_set(:@configuration, nil)
  Featureflow.instance_variable_set(:@client, nil)
  ENV['FEATUREFLOW_SERVER_KEY'] = @original_server_key if instance_variable_defined?(:@original_server_key)
end
