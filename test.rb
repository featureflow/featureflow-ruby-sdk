$:.unshift(File.dirname(__FILE__) + "/lib/")

require 'featureflow'

api_key = 'srv-env-9b5fff890c724d119a334a64ed4d2eb2'
featureflow_client = Featureflow::Client.new(api_key, default_variants: {'default'=>'variant'})
context = Featureflow::ContextBuilder.new('user1').build
puts('test-integration is on? ' + featureflow_client.evaluate('test-integration', context).on?.to_s)
featureflow_client.evaluate('nooooo', context).on?
featureflow_client.evaluate('default', context).on?

#
# loop do
#   puts('test-integration is on? ' + featureflow_client.evaluate('test-integration', context).on?.to_s)
#   sleep 5
# end