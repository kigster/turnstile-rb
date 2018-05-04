module Turnstile
  module Collector
    class RegexpMatcher < Struct.new(:regexp, :extractor)
      # checks if the line matches +regexp+, and if yes
      # runs it through +extractor+ to grab the token
      #
      # @param [String] line read from a log file
      # @return [String] a token in the form 'platform:ip:user'

      def tokenize(line)
        return nil unless matches?(line) && extractor
        extractor[line]
      end

      def matches?(line)
        regexp && regexp.match(line)
      end
    end
  end
end
