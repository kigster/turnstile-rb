require 'logger'
require_relative 'logger/helper'
require_relative 'logger/provider'

module Turnstile
  module Logger
    STDOUT.sync   = true
    @logger       = ::Logger.new(STDOUT)
    @logger.level = ::Logger::INFO
    @enabled      = false

    class << self
      include Provider
    end
  end
end
