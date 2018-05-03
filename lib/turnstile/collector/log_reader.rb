require 'file-tail'
require_relative 'formats'
require_relative 'actor'

module Turnstile
  module Collector
    class LogFile < ::File
      include ::File::Tail
    end

    class LogReader < Actor
      attr_accessor :file, :filename, :matcher, :should_reopen

      def initialize(log_file:, matcher:, **opts)
        super(**opts)
        self.matcher  = matcher
        self.filename = log_file
        self.should_reopen = false
        open_and_watch(opts[:tail] ? opts[:tail].to_i : 0)

        reader = self
        Signal.trap('HUP') { reader.should_reopen = true }
      end

      def reopen(a_file = nil)
        self.should_reopen = false
        close rescue nil
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
          reopen if should_reopen?
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

      def should_reopen?
        should_reopen
      end

      class << self
        include Formats

        def custom(file, queue, **opts)
          new(log_file: file,
              queue:    queue,
              matcher:  custom_matcher,
              **opts)
        end

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

        def delimited(file, queue, **opts)
          new(log_file: file,
              queue:    queue,
              matcher:  delimited_matcher(opts[:delimiter]),
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
