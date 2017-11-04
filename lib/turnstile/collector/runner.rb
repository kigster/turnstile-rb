require 'thread'
require 'daemons/daemonize'
require 'colored2'


module Turnstile
  module Collector
    class Runner
      attr_accessor :config, :queue, :reader, :updater, :file

      def initialize(*args)
        @config = args.last.is_a?(Hash) ? args.pop : {}
        @file   = config[:file]
        @queue  = Queue.new

        config[:debug] ? Turnstile::Logger.enable : Turnstile::Logger.disable

        wait_for_file(@file)

        self.reader
        self.updater

        Daemonize.daemonize if config[:daemonize]
        STDOUT.sync = true if config[:debug]
      end

      def wait_for_file(file)
        sleep_period = 1
        while !File.exist?(file)
          STDERR.puts "File #{file.bold.yellow} does not exist, waiting for it to appear..."
          STDERR.puts 'Press Ctrl-C to abort.' if sleep_period == 1

          sleep sleep_period
          sleep_period *= 1.2
        end
      end

      def run
        threads = [reader, updater].map(&:run)
        threads.last.join
      end

      def updater
        @updater ||= Turnstile::Collector::Updater.new(queue,
                                                       config[:buffer_interval] || 5,
                                                       config[:flush_interval] || 6)
      end

      def log_reader_class
        Turnstile::Collector::LogReader
      end

      def reader
        args    = [file, queue]
        matcher = :default

        if config[:delimiter]
          matcher = :delimited
          args << config[:delimiter]
        elsif config[:filetype]
          matcher = config[:filetype].to_sym
        end

        @reader ||= if log_reader_class.respond_to?(matcher)
                      log_reader_class.send(matcher, *args)
                    else
                      raise ArgumentError, "Invalid matcher #{matcher}"
                    end
      end
    end
  end
end
