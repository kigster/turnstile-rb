require 'turnstile/version'
require 'turnstile/configuration'
require 'turnstile/sampler'
require 'turnstile/adapter'
require 'turnstile/tracker'
require 'turnstile/observer'
require 'turnstile/logger'
require 'turnstile/logger/helper'
require 'turnstile/collector'
require 'turnstile/runner'
require 'turnstile/commands/summary'

module Turnstile
  def self.configure(&block)
    @configuration = Turnstile::Configuration.new.configure(&block)
  end

  def self.config
    @configuration ||= Turnstile::Configuration.new
  end
end
