require 'csv'
require_relative 'base'

module Turnstile
  module Commands
    class FlushCmd < Base

      def execute
        flushdb
      end


      def flushdb
        keys = all_keys
        log_around('wiping the database, total keys: ') do
          with_pipelined do |redis|
            redis.del(keys).to_s
          end
        end
      end
    end
  end
end





