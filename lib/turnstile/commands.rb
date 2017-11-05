require 'active_support/inflector'

require_relative 'commands/base'
require_relative 'commands/show'
require_relative 'commands/flushdb'
require_relative 'commands/print_keys'

module Turnstile
  module Commands
    class << self
      def command(name)
        command_candidate = "#{self.name}::#{ActiveSupport::Inflector.camelize(name)}"
        ActiveSupport::Inflector.constantize command_candidate
      rescue NameError
        raise CommandNotFoundError, "Command #{name} is not found, #{command_candidate}"
      end
    end
  end
end

