require 'csv'
require_relative 'base'

module Turnstile
  module Commands
    class PrintKeys < Base
      def execute
        adapter.all_keys.each do |key|
          puts key
        end
      end
    end
  end
end





