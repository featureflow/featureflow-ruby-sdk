require_relative 'evaluate'
module Featureflow
  class FeatureflowClient
    @default_config = {
        :rtm_url => 'https://rtm.featureflow.io',
        :url => 'https://app.featureflow.io',
        :features => {}
    }
    @default_context = {
      'key' => 'anonymous',
      'values' => {}
    }
    @default_features = {}
    @features = {}

    def initialize
      t1 = Time.now;
      t = set_interval(2.5) {puts Time.now - t1}
    end

    def get_feature(key)
      if @features[key]
        @features[key]
      else
        @default_features[key]
      end
    end

    def set_interval(delay)
      Thread.new do
        loop do
          sleep delay
          yield
        end
      end
    end

    def evaluate(key = '', _context = {'values'=>{}})
      context_key = _context['key'] || @default_context['key']
      values = @default_context['values']
                   .merge(_context['values'])
                   .merge({
                            'featureflow.key' => context_key,
                            'featureflow.date' => Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')
                          })

      new Evaluate key, getFeature(key), @default_features[key], 'key'=>context_key, 'values'=> values
    end
  end
end