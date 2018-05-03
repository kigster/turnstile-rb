require 'turnstile/dependencies'

module Turnstile
  module CLI
    class Launcher
      include Dependencies

      attr_reader :stdin, :stdout, :stderr
      attr_accessor :options

      def initialize(options, stdin = STDIN, stdout = STDOUT, stderr = STDERR)
        self.options            = options
        @stdin, @stdout, @stderr= stdin, stdout, stderr
      end

      def launch
        result = if options[:show]
                   command(:show).execute(options[:show_format] || :json, options[:delimiter])

                 elsif options[:token]
                   tracker.track_token(options[:token], options[:delimiter])

                 elsif options[:flushdb]
                   command(:flushdb).execute

                 elsif options[:print_keys]
                   command(:print_keys).execute

                 elsif options[:file]
                   Turnstile::Collector::Controller.new(options).start
                 end
        puts result if result && !result.empty?
      rescue Exception => e
        handle_error('Error', e)
      end

      def command(name)
        ::Turnstile::Commands.command(name).new(options)
      end

      def handle_error(title, e)
        if options[:trace]
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
