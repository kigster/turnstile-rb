require_relative 'helper'

module Turnstile
  module Logger
    module Provider
      attr_accessor :logger, :enabled

      include Helper


      def enable
        self.enabled = true
        class << self
          self.send(:define_method, :log, proc { |level = :info, msg| _log(level, msg) })
          self.send(:define_method, :logging, proc { |level = :info, msg, &block| _logging(level, msg, &block) })
        end
      end


      def disable
        self.enabled = false
        class << self
          self.send(:define_method, :log, proc { |_| })
          self.send(:define_method, :logging, proc { |_, &block| block.call })
        end
      end


      def log(*)
        # no op
      end


      def logging(*)
        # No op
      end


      private

      def _log(level = :info, msg)
        logger.send(level) do
          "#{sprintf('%-15s', Thread.current[:name] || 'thread-main')} | #{msg}"
        end
      end


      def _logging(level = :info, *args, &_block)
        message = args.join(' ')

        log(level, message) unless block_given?
        return unless block_given?

        start = Time.now
        yield.tap do |result|
          elapsed_time = Time.now - start
          if result
            message += " #{result.to_s}"
          end
          log_elapsed(level, elapsed_time, message)
        end
      rescue Exception => e
        elapsed_time = Time.now - start
        log_elapsed(level, elapsed_time, "error: #{e.message} for #{message}")
      end


      def log_elapsed(level = :info, elapsed_time, message)
        log(level, "(#{'%7.2f' % (1000 * elapsed_time)}ms) #{message}")
      end

    end
  end
end
