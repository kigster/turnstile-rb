require_relative 'session'
require_relative '../logger/helper'

module Turnstile
  module Collector
    class Actor
      include Logger::Helper

      @name = 'abstract'

      class << self
        def actor_name(value = nil)
          @actor_name = value if value
          @actor_name
        end
      end


      attr_accessor :queue,
                    :tracker,
                    :sleep_when_idle,
                    :options,
                    :stopping,
                    :thread

      def initialize(queue:,
                     tracker: nil,
                     sleep_when_idle: 10,
                     **opts)

        self.queue           = queue
        self.sleep_when_idle = sleep_when_idle
        self.tracker         = tracker || Turnstile::Tracker.new
        self.options         = opts
        self.stopping        = false
      end

      def shutdown
        self.stopping = true
        thread.shutdown
      end

      def stopping?
        self.stopping
      end

      def start
        self.thread = create_thread(self, sleep_when_idle) do |actor, sleep_period|
          loop do
            work = actor.execute
            break if actor.stopping?
            sleep(sleep_period) unless work
          end
        end
      end

      def execute
        raise ArgumentError, 'Abstract Method'
      end

      def create_thread(*args, &_block)
        Thread.new(self.class.actor_name, *args) do |actor_name, *args|
          Thread.current[:name] = actor_name
          yield(*args) if block_given?
        end
      end
    end
  end
end
