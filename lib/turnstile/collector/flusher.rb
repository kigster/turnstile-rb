require_relative 'session'

module Turnstile
  module Collector
    class Flusher < Actor

      actor_name :flusher

      def execute
        flush_current_buffer unless queue.empty?
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
        sleep(sleep_when_idle)
      end
    end

    def parse(token)
      a = token.split(':')
      Session.new(a[2], a[0], a[1])
    end
  end
end
