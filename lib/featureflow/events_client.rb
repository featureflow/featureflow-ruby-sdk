require 'excon'
require 'json'

module Featureflow
  class EventsClient
    def initialize(url, api_key)
      @url = url
      @api_key = api_key
    end

    def register_features(with_features)
      Thread.new do
        features = []
        features = with_features.each do | feature |
          features.push(key: feature[:key],
                          variants: feature[:variants],
                          failoverVariant: feature[:failover_variant])
        end
        send_event 'Register Features', :put, 'api/sdk/v1/register', features
      end
    end

    def evaluate(key, evaluated_variant, expected_variant, context)
      Thread.new do
        send_event 'Evaluate Variant', :post, 'api/sdk/v1/events', [{
                                                                      featureKey: key,
                                                                      evaluatedVariant: evaluated_variant,
                                                                      expectedVaraint: expected_variant,
                                                                      context: context
                                                                    }]
      end
    end

    private def send_event(event_name, method, path, body)
      connection = Excon.new(@url)
      response = connection.request(method: method,
                                    path: path,
                                    headers: {
                                      'Authorization' => "Bearer #{@api_key}",
                                      'Content-Type' => 'application/json;charset=UTF-8'
                                    },
                                    omit_default_port: true,
                                    body: JSON.generate(body))
      if response.status >= 400
        Featureflow.logger.error "unable to send event #{event_name} to #{@url+path}. Failed with response status #{response.status}"
        Featureflow.logger.error response.to_s
      end
    rescue => e
      Featureflow.logger.error e.inspect
    end
  end
end