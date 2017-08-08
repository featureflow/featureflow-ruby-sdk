class Featureflow::Configuration
  attr_accessor :api_key
  attr_accessor :endpoint
  attr_accessor :disable_events
  attr_accessor :with_features
  attr_accessor :logger
  
  DEFAULT_ENDPOINT = 'https://app.featureflow.io/api/sdk/v1/features'

  def initialize
    self.api_key = ENV["FEATUREFLOW_SERVER_KEY"]
    self.endpoint = DEFAULT_ENDPOINT
    self.disable_events = false
    self.with_features = []

    self.logger = Logger.new(STDOUT)
    self.logger.level = Logger::WARN
  end

  def validate!
    unless with_features_valid? @with_features
      raise ArgumentError, 'with_features must be an array of Feature hashes. Use Featureflow::Feature.create(key, failover_variant)'
    end
  end

  private

  def with_features_valid?(features)
    features.all? do |feature|
      feature[:key].is_a?(String) && feature[:failover_variant].is_a?(String) && feature[:variants].is_a?(Array)
    end
  end
end