require 'turnstile/version'
require 'turnstile/configuration'
require 'turnstile/commands'
require 'turnstile/logger'
require 'turnstile/dependencies'
require 'turnstile/sampler'
require 'turnstile/tracker'
require 'turnstile/observer'
require 'turnstile/redis/adapter'
require 'turnstile/collector'

require 'turnstile/cli/runner'

module Turnstile
  class CommandNotFoundError < StandardError; end

  class << self
    attr_accessor :debug

    def debug?
      self.debug
    end

    def configure(&block)
      @configuration = create_config.configure(&block)
    end

    def config
      @configuration ||= create_config
    end

    private

    def create_config
      ::Turnstile::Configuration.new
    end

  end

end
