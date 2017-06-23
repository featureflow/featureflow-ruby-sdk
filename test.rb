$:.unshift(File.dirname(__FILE__) + "/lib/")

require 'featureflow'
with_features = [
  Featureflow::Feature.create('default', 'variant')
]



api_key = 'srv-env-9b5fff890c724d119a334a64ed4d2eb2'
featureflow_client = Featureflow::Client.new(api_key: api_key, with_features: with_features)
# context = Featureflow::ContextBuilder.new('user1').build
puts('test-integration is on? ' + featureflow_client.evaluate('test-integration', 'user1').on?.to_s)
featureflow_client.evaluate('nooooo', 'user1').on?
featureflow_client.evaluate('default', 'user1').on?

#
# loop do
#   puts('test-integration is on? ' + featureflow_client.evaluate('test-integration', context).on?.to_s)
#   sleep 5
# end