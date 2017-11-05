require 'file-tail'
require_relative 'formats'
require_relative 'actor'

module Turnstile
  module Collector
    class LogFile < ::File
      include ::File::Tail
    end

    class LogReader < Actor
      attr_accessor :file, :filename, :matcher

      def initialize(log_file:, matcher:, **opts)
        super(**opts)
        self.matcher  = matcher
        self.filename = log_file

        open_and_watch(opts[:tail] ? opts[:tail].to_i : 0)
      end

      def reopen(a_file = nil)
        close
        self.filename = a_file if a_file
        open_and_watch(0)
      end

      def execute
        self.read do |token|
          self.queue << token if token
        end
      rescue IOError
        open_and_watch if File.exist?(filename)
      ensure
        close
      end

      def read(&_block)
        file.tail do |line|
          token = matcher.token_from(line)
          yield(token) if block_given? && token
          break if stopping?
        end
      end

      def close
        (file.close rescue nil) if file
      end

      private

      def open_and_watch(tail_lines = 0)
        self.file = LogFile.new(filename)

        file.interval = 1
        file.backward(0) if tail_lines == 0
        file.backward(tail_lines) if tail_lines > 0
        file.forward(0) if tail_lines == -1
      end

      class << self
        include Formats

        def pipe_delimited(file, queue, **opts)
          new(log_file: file,
              queue:    queue,
              matcher:  delimited_matcher,
              **opts)
        end

        def comma_delimited(file, queue, **opts)
          new(log_file: file,
              queue:    queue,
              matcher:  delimited_matcher(','),
              **opts)
        end

        def colon_delimited(file, queue, **opts)
          new(log_file: file,
              queue:    queue,
              matcher:  delimited_matcher(':'),
              **opts)
        end

        def delimited(file, queue, delimiter, **opts)
          new(log_file: file,
              queue:    queue,
              matcher:  delimited_matcher(delimiter),
              **opts)
        end

        def json_formatted(file, queue, **opts)
          new(log_file: file,
              queue:    queue,
              matcher:  json_matcher,
              **opts)
        end

        alias default pipe_delimited
      end
    end
  end
end
