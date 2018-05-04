require 'turnstile/dependencies'

module Turnstile
  module CLI
    class Launcher
      include Dependencies

      attr_reader :stdin, :stdout, :stderr, :sinatra_thread
      attr_accessor :options

      def initialize(options, stdin = STDIN, stdout = STDOUT, stderr = STDERR)
        self.options            = options
        @stdin, @stdout, @stderr= stdin, stdout, stderr
      end

      def launch
        launch_sinatra_app if options[:web]
        launch_signal_handler

        tdb "config: #{config.to_h}" if Turnstile.config.trace
        result = if options[:show]
                   command(:show).execute(options[:show_format] || :json, options[:delimiter])

                 elsif options[:token]
                   tracker.track_token(options[:token], options[:delimiter])

                 elsif options[:flushdb]
                   command(:flushdb).execute

                 elsif options[:print_keys]
                   command(:print_keys).execute

                 elsif options[:file]
                   controller.start
                 end


        puts result if result && !result.empty?
      rescue SystemExit, SignalException
        exit 6
      rescue Exception => e
        handle_error('Error', e)
      ensure
        sinatra_thread.join if sinatra_thread
      end

      def launch_signal_handler
        Signal.trap('INT') { sleep 1; Kernel.exit(5) }
      end

      def launch_sinatra_app
        @sinatra_thread = Thread.new do
          require_relative '../web_app'
          Kernel.exit(0)
        end
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

      private

      def controller
        @controller ||= Turnstile::Collector::Controller.new(options)
      end

    end
  end
end
