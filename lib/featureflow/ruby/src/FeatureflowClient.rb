require_relative 'Evaluate'

class FeatureflowClient
  @default_context = {
    'key' => 'anonymous',
    'values' => {}
  }
  @default_features = {}
  def initialize

  end

  def getFeature(key)

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