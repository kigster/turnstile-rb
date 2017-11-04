module Turnstile
  module Logger
    module Helper
      def self.included(base)
        base.extend(Helper)
      end

      def debug(*args, &block)
        Turnstile::Logger.log(:debug, *args, &block)
      end

      def info(*args, &block)
        Turnstile::Logger.log(:info, *args, &block)
      end

      def warn(*args, &block)
        Turnstile::Logger.log(:warn, *args, &block)
      end

      def error(*args, &block)
        Turnstile::Logger.log(:error, *args, &block)
      end

      def with_duration(level = :info, *args, &block)
        Turnstile::Logger.logging(level, *args, &block)
      end

      def info_elapsed(*args, &block)
        with_duration(:info, *args, &block)
      end

      def error_elapsed(*args, &block)
        with_duration(:error, *args, &block)
      end

      alias with_logging info_elapsed
      alias around_logging info_elapsed
      alias log_around info_elapsed

    end
  end
end
