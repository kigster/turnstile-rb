require_relative 'logger/helper'
module Turnstile
  module Dependencies
    def self.included(base)
      base.include(Turnstile::Logger::Helper)
      base.class_eval do

        def tracker
          @tracker ||= Tracker.new
        end

        def adapter
          @adapter ||= Redis::Adapter.instance
        end

        def sampler
          @sampler ||= Sampler.new
        end

        def config
          @config ||= Turnstile.config
        end

        def aggregate
          adapter.aggregate
        end

      end
    end
  end
end
