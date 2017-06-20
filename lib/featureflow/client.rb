require 'excon'
require 'time'
require 'pp'
require 'json'
require 'featureflow/evaluate'

module Featureflow
  class Client
    FEATURE_CONTROL_REST_PATH = '/api/sdk/v1/features'
    DEFAULT_CONTEXT = {
      'key' => 'anonymous',
      'values' => {}
    }

    def initialize(api_key, config = {})
      @features = {}
      @config = {
        api_key: api_key,
        rtm_url: 'https://rtm.featureflow.io',
        url: 'https://featureflow.featureflow.io',
        features: {}
      }.merge(config)

      start_evaluator(15)
    end

    def feature(key)
      @features[key]
    end

    def start_evaluator(delay = 15)
      Thread.new do
        loop do
          begin
            response = Excon.get(@config[:url] + FEATURE_CONTROL_REST_PATH, headers: {
                'Authorization' => 'Bearer ' + @config[:api_key],
                'Accept' => '*/*'
            }, omit_default_port: true)
            @features = JSON.parse(response.body)
            # pp @features
          rescue => e
            puts e.inspect
            end
          sleep delay
        end
      end
    end

    def evaluate(key = '', context = {'values' => {}})
      context_key = context['key'] || DEFAULT_CONTEXT['key']
      values = DEFAULT_CONTEXT['values'].merge(context['values'])
                                        .merge(
                                          'featureflow.key' => context_key,
                                          'featureflow.date' => Time.now.iso8601
                                         )
      Evaluate.new key, feature(key), @config[:features][key], 'key' => context_key, 'values' => values
    end
  end
end