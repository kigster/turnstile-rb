require_relative 'session'

module Turnstile
  module Collector
    class Flusher < Actor

      actor_name :flusher

      def execute
        flush_current_buffer unless queue.empty?
        queue.size
      rescue Exception => e
        puts e.backtrace.reverse.join("\n")
        puts e.inspect.red
        raise e
      end

      def flush_current_buffer
        item = queue.pop
        return unless item
        session = parse(item)
        tracker.track(session.uid,
                      session.platform,
                      session.ip) if session.uid
      end

      def parse(token)
        # platform, IP, user
        a = token.split(':')

        # session is backwards
        Session.new(a[2], a[0], a[1])
      end
    end
  end
end
