require 'featureflow/rails/rails_client'
class Featureflow::FeatureflowRailtie < Rails::Railtie
  config.before_initialize do
    ActiveSupport.on_load(:action_controller) do
      ActionController::Base.class_eval do
        def featureflow
          @featureflow ||= Featureflow::RailsClient.new(request)
        end
      end
    end
  end
end