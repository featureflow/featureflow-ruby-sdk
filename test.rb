$:.unshift(File.dirname(__FILE__) + "/lib/")

require 'featureflow'
with_features = [
  Featureflow::Feature.create('default', 'variant'),
  Featureflow::Feature.create('oli-f1', 'off')
]



api_key = 'srv-env-'
config = Featureflow::Configuration.new
config.api_key = api_key
#config.endpoint = 'http://localhost:8081'
#config.event_endpoint = 'http://localhost:8081'
config.with_features = with_features

featureflow_client = Featureflow::Client.new(config)
=begin
featureflow_client = Featureflow::Client.new(api_key: api_key, with_features: with_features, url: 'http://localhost:8081')
=end
user = Featureflow::UserBuilder.new('user1').build
puts('test-integration is on? ' + featureflow_client.evaluate('test-integration', user).on?.to_s)
featureflow_client.evaluate('nooooo', user).on?
featureflow_client.evaluate('default', user).on?

#
loop do
  sleep 10
  puts(featureflow_client.evaluate('oli-f1', user).value)
  puts(featureflow_client.evaluate('oli-f1', user).is?('extended'))
  puts(featureflow_client.evaluate('default', user).on?)
end
