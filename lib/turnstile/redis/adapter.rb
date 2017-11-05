require 'redis'
require 'timeout'
require 'singleton'
require 'connection_pool'
require_relative '../logger/helper'
require_relative 'connection'

module Turnstile
  module Redis
    class Adapter
      SEP = ':'

      include Singleton
      include Logger::Helper
      include Connection

      attr_accessor :connection_pool, :config

      # noinspection RubyResolve
      def add(uid, platform, ip)
        key = compose_key(uid, platform, ip)
        timeout(config.redis.timeout) do
          with_redis do |redis|
            redis.setex(key, config.activity_interval, 1)
          end
        end
      rescue StandardError => e
        error "exception while writing to redis: #{e.inspect}"
      end


      def fetch
        all_keys.map do |key|
          fields = key.split(SEP)
          {
            uid:      fields[1],
            platform: fields[2],
            ip:       fields[3],
          }
        end
      end


      def all_keys
        with_redis do |redis|
          redis.keys("#{prefix}*")
        end
      end


      def aggregate
        all_keys.inject({}) { |hash, key| increment_platform(hash, key) }.tap do |h|
          h['total'] = h.values.inject(&:+) || 0
        end
      end


      def increment_platform(hash, key)
        tuple = key.flatten if key.is_a?(Array)
        tuple = key.split(SEP) if key.is_a?(String)

        platform = tuple[2]

        raise ArgumentError , "can't determine platform from the key #{key.inspect}" unless platform

        hash[platform] ||= 0
        hash[platform] += 1
        hash
      end


      def config
        Turnstile.config
      end

      def rconfig
        config.redis
      end


      def compose_key(uid, platform = nil, ip = nil)
        "#{prefix}#{uid}#{SEP}#{platform}#{SEP}#{ip}"
      end


      # def redis
      #   @redis ||= ConnectionPool::Wrapper.new(size: 3, timeout: 15, &redis_factory)
      # end


      private

      def initialize(config = Turnstile.config)
        self.config = config
        self.connection_pool
      end


      def prefix
        @prefix ||= "#{Turnstile::NS}|#{config.redis.namespace.gsub(/#{SEP}/, ':')}#{SEP}"
      end
    end
  end
end

