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
  class ConfigFileError < StandardError; end
  class HiredisDriverNotFound < StandardError; end

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

Kernel.send(:define_method, :tdb) do |msg, io = STDOUT|
   io.puts ''.green + ' debug '.black.on.green+ ''.green + ' —— ' + msg
end

Kernel.send(:define_method, :terr) do |msg, io = STDERR|
   io.puts ''.bold.red + ' error '.bold.white.on.red + ''.red + ' —— ' + msg
end
