require 'featureflow/version'
require 'featureflow/client'
require 'featureflow/context_builder'
require 'featureflow/feature'

module Featureflow
  class << self
    attr_writer :logger

    def logger
      @logger ||= Logger.new($stderr).tap do |log|
        log.progname = self.name
      end
    end
  end
end