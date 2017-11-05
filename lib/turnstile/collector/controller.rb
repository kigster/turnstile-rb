require 'csv'
require 'thread'
require 'hashie/extensions/symbolize_keys'
require 'daemons/daemonize'
require 'colored2'
require 'attr_memoized'

require_relative 'flusher'
require_relative 'actor'

module Turnstile
  module Collector
    class Controller
      include AttrMemoized

      attr_memoized :tracker, -> { Turnstile::Tracker.new }
      attr_memoized :queue, -> { Queue.new }
      attr_memoized :file, -> { options.file }

      attr_accessor :options, :actors

      def initialize(*args)
        self.options = args.last.is_a?(Hash) ? args.pop : {}

        options.verbose ? Turnstile::Logger.enable : Turnstile::Logger.disable

        wait_for_file(file)

        self.actors = [ self.reader, self.flusher ]

        Daemonize.daemonize if options[:daemonize]
        STDOUT.sync = true if options[:verbose]
      end

      def start
        threads = actors.map(&:start)
        threads.map(&:join)
      end

      def flusher
        @flusher ||= Flusher.new(**flusher_arguments)
      end

      def reader
        opts = reader_arguments
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

      private


      def flusher_arguments
        symbolize(actor_argument_hash.merge(sleep_when_idle: options[:flush_interval] || 10))
      end

      def reader_arguments
        reader_args_hash   = actor_argument_hash.merge(sleep_when_idle: options[:flush_interval] || 10)
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
        while !File.exist?(file)
          STDERR.puts "File #{file.bold.yellow} does not exist, waiting for it to appear..."
          STDERR.puts 'Press Ctrl-C to abort.' if sleep_period == 1

          sleep sleep_period
          sleep_period *= 1.2
        end
        STDOUT.puts "Detected file #{file.bold.yellow} now exists, continue..."
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
