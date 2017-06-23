$:.unshift(File.dirname(__FILE__) + "/lib/")

require 'featureflow'
with_features = [
  Featureflow::Feature.create('default', 'variant')
]



# api_key = 'srv-env-9b5fff890c724d119a334a64ed4d2eb2'
api_key = 'srv-env-f472cfa8c2774ea2b3678fc5a3dbfe13'
featureflow_client = Featureflow::Client.new(api_key: api_key, with_features: with_features, url: 'http://10.10.2.163:8081')
context = Featureflow::ContextBuilder.new('user1').build
puts('test-integration is on? ' + featureflow_client.evaluate('test-integration', context).on?.to_s)
featureflow_client.evaluate('nooooo', context).on?
featureflow_client.evaluate('default', context).on?

#
loop do
  sleep 1
end