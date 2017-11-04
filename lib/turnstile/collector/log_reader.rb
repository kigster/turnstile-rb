require 'file-tail'
require 'turnstile/collector/formats'

module Turnstile
  module Collector
    class LogFile < ::File
      include ::File::Tail
    end

    class LogReader
      class << self
        include Formats

        def pipe_delimited(file, queue)
          new(file, queue, delimited_matcher)
        end

        def comma_delimited(file, queue)
          new(file, queue, delimited_matcher(','))
        end

        def colon_delimited(file, queue)
          new(file, queue, delimited_matcher(':'))
        end

        def delimited(file, queue, delimiter)
          new(file, queue, delimited_matcher(delimiter))
        end

        def json_formatted(file, queue)
          new(file, queue, json_matcher)
        end

        alias default pipe_delimited
      end

      attr_accessor :file, :queue, :matcher

      def initialize(log_file, queue, matcher)
        self.matcher = matcher
        self.queue   = queue

        self.file = LogFile.new(log_file)

        file.interval = 1
        file.backward(0)
      end

      def run
        Thread.new do
          Thread.current[:name] = 'log-reader'
          Turnstile::Logger.log "starting to tail file #{file.path}...."
          process!
        end
      end

      def read(&_block)
        file.tail do |line|
          token = matcher.token_from(line)
          yield(token) if block_given? && token
        end
      end

      def process!
        self.read do |token|
          queue << token if token
        end
      end

      def close
        (file.close if file) rescue nil
      end

      private

      def extract(line)
      end
    end

  end
end
