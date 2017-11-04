require 'csv'
module Turnstile
  class Summary

    class << self
      def print(method, delimiter = nil)
        summary = new
        if summary.respond_to?(method)
          STDOUT.puts summary.send(method, delimiter)
        else
          STDERR.puts "don't know how to use format '#{method}'mac"
        end
      end
    end

    def json(*)
      out = "{\n"
      first = true
      aggregate.each_pair do |key, value|
        out << ",\n" unless first
        first = false
        out << json_row(key, value)
      end
      out << "\n}"
      out
    end

    def nad(*)
      out = ''
      aggregate.each_pair do |key, value|
        out << nad_row(key, value)
      end
      out
    end

    def csv(delimiter = nil)
      out = CSV.generate do |csv|
        aggregate.each_pair do |key, value|
          csv << [key, value]
        end
      end
      delimiter ? out.gsub(/,/m, delimiter) : out
    end

    def nad_row(key, value)
      %Q(turnstile:#{key}#{"\tn\t"}#{value}\n)
    end

    def json_row(key, value)
      %Q(  "#{key}": #{value})
    end

    def aggregate
      Turnstile::Adapter.new.aggregate
    end
  end
end
