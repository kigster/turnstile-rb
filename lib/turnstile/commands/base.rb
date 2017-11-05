require 'turnstile/dependencies'

module Turnstile
  module Commands
    class Base
      include Dependencies

      attr_accessor :options, :config

      def initialize(options, config = Turnstile.config)
        self.options = options
        self.config  = config
      end

    end
  end
end


