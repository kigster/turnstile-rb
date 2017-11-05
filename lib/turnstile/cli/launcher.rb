require 'turnstile/dependencies'

module Turnstile
  module CLI
    class Launcher
      include Dependencies

      attr_accessor :options

      def initialize(options)
        self.options = options
      end

      def launch
        if options.show
          command(:show).execute(options[:show_format] || :json, options[:delimiter])

        elsif options.token
          tracker.track_token(options[:token], options[:delimiter])

        elsif options.flushdb
          count = adapter.flushdb
          stdout.puts "Deleted a total of #{count} keys."

        else
          Turnstile::Collector::Runner.new(options).run
        end
      rescue Exception => e
        handle_error('Parser#run error:', e)
      end

      def handle_error(title, e)
        if options[:debug]
          trace = e.backtrace.reverse
          last  = trace.pop
          stderr.puts trace.join("\n")
          stderr.puts last.bold.red
        end
        stderr.puts

        stderr.puts title.bold.yellow
        stderr.puts "\t" + e.message.red
        stderr.puts
      end

    end
  end
end
