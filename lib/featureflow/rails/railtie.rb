require 'featureflow/rails/rails_client'
module Featureflow
  LOCK = Mutex.new

  class << self
    def configure(config_hash=nil)
      if config_hash
        configuration.merge!(config_hash)
      end

      yield(configuration) if block_given?
      yield(featureflow) if block_given?
    end

    # Configuration getters
    def configuration
      @configuration = nil unless defined?(@configuration)
      @configuration || LOCK.synchronize { @configuration ||= {} }
    end

    # Configuration getters
    def featureflow
      @featureflow = nil unless defined?(@featureflow)
      @featureflow || LOCK.synchronize { @featureflow ||= Featureflow::Client.new(configuration) }
    end
  end

  class FeatureflowRailtie < Rails::Railtie

    config.before_initialize do
      ActiveSupport.on_load(:action_controller) do
        # @client =
        ActionController::Base.class_eval do
          def configure_featureflow
            @featureflow = Featureflow::RailsClient.new(request)
          end

          before_action :configure_featureflow
        end
      end
    end

  end
end