require 'thread'
require 'daemons/daemonize'
require 'colored2'
require 'attr_memoized'

require_relative 'flusher'
require_relative 'actor'

module Turnstile
  module Collector
    class Runner
      include AttrMemoized

      attr_memoized :tracker, -> { Turnstile::Tracker.new }
      attr_memoized :queue, -> { Queue.new }
      attr_memoized :file, -> { config.file }


      attr_accessor :config

      def initialize(*args)
        self.config = args.last.is_a?(Hash) ? args.pop : {}

        config.verbose ? Turnstile::Logger.enable : Turnstile::Logger.disable

        wait_for_file(file)

        self.reader
        self.flusher

        Daemonize.daemonize if config[:daemonize]
        STDOUT.sync = true if config[:verbose]
      end

      def run
        threads = [reader.start, flusher.start]
        threads.map(&:join)
      end

      def flusher
        @flusher ||= Flusher.new(**flusher_arguments)
      end

      def reader
        return @reader if @reader

        args, opts = reader_arguments
        matcher    = opts.delete(:matcher)

        @reader ||= if log_reader_class.respond_to?(matcher)
                      log_reader_class.send(matcher, *args, **opts)
                    else
                      raise ArgumentError, "Invalid matcher #{matcher}, args #{reader_args}"
                    end
      end

      def actor_arguments
        [queue, tracker]
      end

      def actor_argument_hash
        {}
      end

      def flusher_arguments
        actor_argument_hash.merge(sleep_when_idle: config[:flush_interval] || 10)
      end

      def reader_arguments
        reader_args        = actor_arguments
        reader_args_hash   = actor_argument_hash.merge(sleep_when_idle: config[:flush_interval] || 10)
        matcher, delimiter = select_matcher

        reader_args.push(delimiter) if delimiter
        reader_args_hash.merge!(matcher: matcher)
        return reader_args, reader_args_hash
      end

      private

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

        if config[:delimiter]
          matcher   = :delimited
          delimiter = config[:delimiter]
        elsif config[:filetype]
          matcher = config[:filetype].to_sym
        end
        return matcher, delimiter
      end
    end
  end
end
