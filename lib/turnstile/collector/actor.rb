require_relative 'session'
require_relative '../logger/helper'
require_relative '../dependencies'
require 'turnstile'
require 'thread'
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
                     sleep_when_idle: Turnstile.config.flush_interval,
                     **opts)

        self.queue           = queue
        self.sleep_when_idle = sleep_when_idle
        self.tracker         = tracker || Turnstile::Tracker.new
        self.options         = opts
        self.stopping        = false

        Kernel.tdb "actor initialized: #{self.to_s}" if Turnstile.config.trace
      end

      def shutdown
        self.stopping = true
      end

      def config
        @config ||= Turnstile.config
      end

      def stopping?
        self.stopping
      end

      def start
        self.thread = create_thread(self, sleep_when_idle) do |actor, sleep_period|
          loop do
            items_remaining = actor.execute
            break if actor.stopping?
            sleep(sleep_period) unless items_remaining && items_remaining > 0
          end
        end
      end

      def to_s
        "<turnsile-actor##{self.class.name.gsub(/.*::/, '').downcase}: queue size: #{queue.size}, idle=#{sleep_when_idle}"
      end

      # Return nil when there is nothing else to do
      # Return ideally a number representing number of remaining items.
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
