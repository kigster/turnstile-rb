require 'turnstile/redis/adapter'
require 'turnstile/sampler'

module Turnstile
  module Dependencies

    def self.included(base)
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

        def command(name)
          ::Turnstile::Commands.const_get(name.to_s.capitalize.to_sym)
        rescue NameError
          nil
        end

      end
    end
  end
end
