require 'hashie/dash'
require 'hashie/extensions/dash/property_translation'
require 'pp'

module Turnstile
  class RedisConfig < ::Hashie::Dash
    include Hashie::Extensions::Dash::PropertyTranslation

    property :url, required: false
    property :host, default: '127.0.0.1', required: true
    property :port, default: 6379, required: true, transform_with: ->(value) { value.to_i }
    property :db, default: 1, required: true, transform_with: ->(value) { value.to_i }
    property :timeout, default: 0.05, required: true, transform_with: ->(value) { value.to_f }
    property :namespace, default: '', required: false
    property :pool_size, default: 5, required: true

    def configure
      yield self if block_given?
      self
    end
  end

  class Configuration < ::Hashie::Dash
    include Hashie::Extensions::Dash::PropertyTranslation
    property :activity_interval, default: 60, required: true, transform_with: ->(value) { value.to_i }
    property :sampling_rate, default: 100, required: true, transform_with: ->(value) { value.to_i }
    property :redis, default: ::Turnstile::RedisConfig.new
    property :custom_matcher

    def configure
      yield self if block_given?
      self
    end

    class << self
      def from_file(file = nil)
        return unless file
        require(normalize(file))
      rescue Exception => e
        raise ConfigFileError.new("Error reading configuration from a file #{file}: #{e.message}")
      end

      private

      def normalize(file)
        file.start_with?('/') ? file : Dir.pwd + '/' + file
      end
    end

    def method_missing(method, *args, &block)
      return super unless method.to_s =~ /^redis_/
      prop = method.to_s.gsub(/^redis_/, '').to_sym
      if self.redis.respond_to?(prop)
        prop.to_s.end_with?('=') ? self.redis.send(prop, *args, &block) : self.redis.send(prop)
      end
    end
  end
end
