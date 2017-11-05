require 'csv'
require_relative 'base'

module Turnstile
  module Commands
    class Flushdb < Base
      def execute
        flushdb
      end

      def flushdb
        adapter.flushdb
      end
    end
  end
end





