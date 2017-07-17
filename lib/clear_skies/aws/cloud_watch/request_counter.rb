module ClearSkies
  module AWS

    module CloudWatch
      class RequestCounter < Seahorse::Client::Handler
        @mutex = Mutex.new
        def self.increment
          @mutex.synchronize do
            @count ||= 0
            @count += 1
          end
        end

        def self.count
          @count ||= 0
          @count
        end

        def initialize(handler)
          @handler = handler
        end

        def call(context)
          RequestCounter.increment
          @handler.call(context)
        end
      end

      class RequestCounterPlugin < Seahorse::Client::Plugin

        def add_handlers(handlers, config)
          handlers.add(RequestCounter, step: :validate)
        end

      end
    end
  end
end

Aws::CloudWatch::Client.add_plugin(ClearSkies::AWS::CloudWatch::RequestCounterPlugin)
