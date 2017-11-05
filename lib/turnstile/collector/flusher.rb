require_relative 'session'

module Turnstile
  module Collector
    class Flusher < Actor

      actor_name :flusher

      def execute
        unless queue.empty?
          flush_current_buffer
        end
        queue.size
      end

      def flush_current_buffer
        info_elapsed "flushing queue, size #{keys.size}" do
          while !queue.empty?
            session = parse(queue.pop)
            tracker.track(session.uid,
                          session.platform,
                          session.ip) if session.uid
          end
        end
        info "queue drained, sleeping #{sleep_when_idle}secs."
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
