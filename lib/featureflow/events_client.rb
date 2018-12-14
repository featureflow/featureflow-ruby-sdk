require 'excon'
require 'json'
require 'thread'
require 'time'

module Featureflow
  #LOCK = Mutex.new

  class EventsClient
    def initialize(url, api_key)
      @url = url
      @api_key = api_key
      @eventsQueue = Queue.new
      @scheduler = start_scheduler
    end

    def start_scheduler()
      Thread.new do
        loop do
          begin
            sleep 10
            send_queue
          end
        end
      end
    end

    #register features are not queued and go straight out
    def register_features(with_features)
      Thread.new do
        features = []
        features = with_features.each do | feature |
          features.push(key: feature[:key],
                          variants: feature[:variants],
                          failoverVariant: feature[:failover_variant])
        end
        send_event 'Register Features', :put, '/api/sdk/v1/register', features
      end
    end

    def evaluate(key, evaluated_variant, expected_variant, user)
      Thread.new do
        timestamp = Time.now.iso8601
        queue_event  ({
             featureKey: key,
             evaluatedVariant: evaluated_variant,
             expectedVaraint: expected_variant,
             user: user,
             timestamp: timestamp
       })
      end
    end

    def queue_event(event)
      #add to queue

        @eventsQueue.push(event)

        if !@scheduler.alive?
          @scheduler = start_scheduler
        end

      if @eventsQueue.length >= 10000
        send_queue
      end
      #id queue = 10000 then send_queue
    end

    def send_queue()
        events  =[]
        begin
          loop do
            events << @eventsQueue.pop(true)
          end
        rescue ThreadError
        end

        if !events.empty?
          send_event 'Evaluate Variant', :post, '/api/sdk/v1/events', events
        end

    end

=begin
    private def send_queue()

      connection = Excon.new(@url)
      response = connection.request(method: method,
                                    path: path,
                                    headers: {
                                      'Authorization' => "Bearer #{@api_key}",
                                      'Content-Type' => 'application/json;charset=UTF-8',
                                      'X-Featureflow-Client' => 'RubyClient/' + Featureflow::VERSION
                                    },
                                    omit_default_port: true,
                                    body: JSON.generate(body))
      if response.status >= 400
        Featureflow.logger.error "unable to send event #{event_name} to #{@url+path}. Failed with response status #{response.status}"
        Featureflow.logger.error response.to_s
      end
    rescue => e
      Featureflow.logger.error e.inspect
    end
=end

    private def send_event(event_name, method, path, body)
      connection = Excon.new(@url)
      response = connection.request(method: method,
                                    path: path,
                                    headers: {
                                        'Authorization' => "Bearer #{@api_key}",
                                        'Content-Type' => 'application/json;charset=UTF-8',
                                        'Accept' => 'Application/Json',
                                        'X-Featureflow-Client' => 'RubyClient/' + Featureflow::VERSION
                                    },
                                    omit_default_port: true,
                                    body: JSON.generate(body))
      if response.status >= 400
        Featureflow.logger.error "unable to send event #{event_name} to #{@url+path}. Failed with response status #{response.status}"
        Featureflow.logger.error response.to_s
      end
    rescue => e
      Featureflow.logger.error e.inspect
    end

  end
end
