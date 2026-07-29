require 'featureflow/client'
require 'featureflow/user_builder'

module Featureflow
  class RailsClient
    def initialize(request)
      @request = request
    end

    # `user` is whatever Client#evaluate accepts: a String user id, or a user
    # Hash built with Featureflow::UserBuilder ({id:, attributes:}). The current
    # request's ip and url are merged in as implicit attributes so targeting
    # rules can match on them; anything the caller set explicitly wins.
    def evaluate(key, user)
      Featureflow.evaluate(key, with_request_attributes(user))
    end

    private

    def with_request_attributes(user)
      user = UserBuilder.new(user).build if user.is_a?(String)
      # Anything else is left alone so Client#evaluate raises its own ArgumentError.
      return user unless user.is_a?(Hash)

      user.merge(attributes: request_attributes.merge(user[:attributes] || {}))
    end

    # Attribute keys are Strings throughout the evaluation path (UserBuilder
    # normalises them), so the request attributes are keyed as Strings too.
    def request_attributes
      {
        'featureflow.ip' => @request.remote_ip,
        'featureflow.url' => @request.original_url
      }
    end
  end
end
