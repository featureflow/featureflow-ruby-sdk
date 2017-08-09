require 'featureflow/rails/request_parser'

class Featureflow::Middleware
  def initialize(app)
    @app = app
  end

  def call(env)
    Featureflow::Client.default_context_values = Featureflow::RequestParser.new(env).parse
    @app.call(env).tap { Featureflow::Client.clear_default_context_values }
  end
end