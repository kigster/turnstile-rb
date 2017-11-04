module Turnstile
  module Collector
    class Matcher < Struct.new(:regexp, :extractor)
      # checks if the line matches +regexp+, and if yes
      # runs it through +extractor+ to grab the token
      #
      # @param [String] line read from a log file
      # @return [String] a token in the form 'platform:ip:user'

      def token_from(line)
        return nil unless matches?(line)
        return nil unless extractor
        extractor ? extractor[line] : nil
      end

      def matches?(line)
        regexp && regexp.match?(line)
      end
    end
  end
end
