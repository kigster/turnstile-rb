require 'csv'
require 'thread'
require 'hashie/extensions/symbolize_keys'
require 'daemons/daemonize'
require 'colored2'

require_relative 'flusher'
require_relative 'actor'

module Turnstile
  module Collector
    class Controller
      attr_accessor :options, :actors, :threads

      def initialize(*args)
        self.options = args.last.is_a?(Hash) ? args.pop : {}

        options.verbose ? Turnstile::Logger.enable : Turnstile::Logger.disable

        wait_for_file(file)

        self.actors = [self.reader, self.flusher]

        Daemonize.daemonize if options[:daemonize]
        STDOUT.sync = true if options[:verbose]
      end

      def start
        self.threads = actors.map(&:start)
        threads.map(&:join)
      end

      def stop
        actors.each(&:shutdown)
      end

      def flusher
        @flusher ||= Flusher.new(**flusher_arguments)
      end

      def tracker
        @tracker ||= Turnstile::Tracker.new
      end

      def queue
        @queue ||= Queue.new
      end

      def file
        options.file
      end

      def reader
        opts    = reader_arguments
        matcher = opts.delete(:matcher).to_sym
        @reader ||= if log_reader_class.respond_to?(matcher)
                      log_reader_class.send(matcher, file, queue, **opts)
                    else
                      raise ArgumentError, "Invalid matcher #{matcher}, args #{reader_args}"
                    end
      end

      def symbolize(opts)
        Hashie::Extensions::SymbolizeKeys.symbolize_keys(opts.to_h)
      end

      def config
        @config ||= Turnstile.config
      end

      private

      def flusher_arguments
        symbolize(actor_argument_hash.merge(sleep_when_idle: config.flush_interval))
      end

      def reader_arguments
        reader_args_hash   = actor_argument_hash.merge(sleep_when_idle: config.flush_interval)
        matcher, delimiter = select_matcher

        reader_args_hash.merge!(delimiter: delimiter) if delimiter
        reader_args_hash.merge!(matcher: matcher) if matcher

        symbolize(reader_args_hash)
      end

      def actor_argument_hash
        options.merge(queue: queue, tracker: tracker)
      end

      def wait_for_file(file)
        sleep_period = 1
        while !::File.exist?(file)
          terr "File #{file.bold.yellow} does not exist, waiting for it to appear..."
          terr 'Press Ctrl-C to abort.' if sleep_period == 1

          sleep sleep_period
          sleep_period *= 1.2
        end
        tdb "Detected file #{file.bold.yellow} now exists, continue..."
      end

      def log_reader_class
        Turnstile::Collector::LogReader
      end

      def select_matcher
        matcher   = :default
        delimiter = nil

        if options[:delimiter]
          matcher   = :delimited
          delimiter = options[:delimiter]
        elsif options[:filetype]
          matcher = options[:filetype].to_sym
        end
        return matcher, delimiter
      end
    end
  end
end
