require 'featureflow/client'

module Featureflow
  class RailsClient
    def initialize(request)
      @request = request
    end

    def evaluate(key, context)
      request_context_values = {
        'featureflow.ip' => @request.remote_ip,
        'featureflow.url' => @request.original_url
      }
      context = {key: context, values: {}} if context.is_a?(String)
      Featureflow.evaluate(key, key: context[:key], values: request_context_values.merge(context[:values]))
    end
  end
end