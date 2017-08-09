require 'logger'
require 'featureflow/version'
require 'featureflow/configuration'
require 'featureflow/client'
require 'featureflow/context'
require 'featureflow/feature'

module Featureflow
  class << self
    def configure(config_hash = nil)
      if config_hash
        config_hash.each do |k, v|
          configuration.send("#{k}=", v) rescue nil if configuration.respond_to?("#{k}=")
        end
      end

      yield(configuration) if block_given?
    end

    def configuration
      @configuration ||= Featureflow::Configuration.new
    end

    def logger
      configuration.logger
    end

    def client
      @client ||= Featureflow::Client.new(configuration)
    end

    alias featureflow client

    def evaluate(key, *args)
      client.evaluate(key, *args)
    end
  end
end

require 'featureflow/rails/railtie' if defined?(Rails)