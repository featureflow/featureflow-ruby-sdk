require 'featureflow/rails/middleware'

class Featureflow::FeatureflowRailtie < Rails::Railtie
  config.before_initialize do
    ActiveSupport.on_load(:action_controller) do
      ActionController::Base.class_eval do
        def featureflow
          Featureflow.featureflow
        end

        alias ff featureflow

        helper_method :featureflow, :ff
      end
    end
  end

  initializer "featureflow.middleware" do |app|
    app.config.middleware.use Featureflow::Middleware
  end
end