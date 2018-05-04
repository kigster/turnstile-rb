require 'csv'
require_relative 'base'

module Turnstile
  module Commands
    class Show < Base

      def execute(format = :json, delimiter = nil)
        STDOUT.puts render_totals(format, delimiter)
      end

      def render_totals(format, delimiter = nil)
        unless self.respond_to?(format)
          raise ArgumentError, "Format #{format} is not supported"
        end
        self.send(format, aggregate, delimiter)
      end

      def yaml(data, *)
        build_string(data, "\n", "---\nturnstile:") { |key, value, *| yaml_row(key, value) }
      end

      # Formats supported for the output
      # JSON
      def json(data, *)
        build_string(data, "\n", '{', '}') do |key, value, index:, last:, first:|
          json_row(key, value, index: index, first: first, last: last)
        end
      end


      # NAD format for Circonus
      def nad(data, *)
        build_string(data) { |key, value, *| nad_row(key, value) }
      end


      # CSV Format
      def csv(data, delimiter = nil)
        build_string(data) do |key, value, *|
          string = [key, value].to_csv
          string.gsub!(/,/, delimiter) if delimiter
          string.strip
        end
      end

      private

      # This method is used to build a string with
      # opening/closing parts and looping contents inside.
      #
      def build_string(data,
                       joiner = "\n",
                       prefix = nil,
                       suffix = nil,
                       &_block)
        slices = []
        slices << prefix if prefix
        index = 0; count = data.size
        data.each_pair do |key, value|
          slices << yield(
            key,
              value,
              index: index,
              first: (index == 0),
              last: (index == count - 1)
          ).to_s
          index += 1
        end
        slices << suffix if suffix
        slices.compact.join(joiner).strip
      end

      def json_row(key, value, last: false, **)
        %Q(  "#{key}": #{value}#{ last ? '' : ',' })
      end


      def nad_row(key, value)
        %Q(turnstile:#{key}#{"\tn\t"}#{value})
      end

      def yaml_row(key, value)
        %Q(  #{key}: #{value})
      end

    end
  end
end
