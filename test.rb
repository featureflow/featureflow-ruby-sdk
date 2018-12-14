$:.unshift(File.dirname(__FILE__) + "/lib/")

require 'featureflow'
with_features = [
  Featureflow::Feature.create('default', 'variant'),
  Featureflow::Feature.create('oli-f1', 'off')
]



api_key = 'srv-env-...'
config = Featureflow::Configuration.new
config.api_key = api_key
config.endpoint = 'http://localhost:8081'
config.event_endpoint = 'http://localhost:8081'
config.with_features = with_features

featureflow_client = Featureflow::Client.new(config)
=begin
featureflow_client = Featureflow::Client.new(api_key: api_key, with_features: with_features, url: 'http://localhost:8081')
=end
context = Featureflow::ContextBuilder.new('user1').build
puts('test-integration is on? ' + featureflow_client.evaluate('test-integration', context).on?.to_s)
featureflow_client.evaluate('nooooo', context).on?
featureflow_client.evaluate('default', context).on?

#
loop do
  sleep 10
  featureflow_client.evaluate('oli-f1', context).value
  featureflow_client.evaluate('oli-f1', context).is?('extended')
  featureflow_client.evaluate('default', context).on?
end